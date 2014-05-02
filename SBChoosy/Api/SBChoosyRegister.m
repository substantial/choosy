
#import "SBChoosyRegister.h"
#import "SBChoosyActionContext.h"
#import "SBChoosy.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyAppType+Protected.h"
#import "NSThread+Helpers.h"

@interface SBChoosyRegister ()

@property (nonatomic) NSMutableArray *appTypes; //downloaded, processed app types
@property (nonatomic) NSMutableArray *registeredAppTypeKeys; // app types Choosy was told to care about
@property (nonatomic) NSOperationQueue *appTypesSerialAccessQueue;
@property (nonatomic) NSMutableDictionary *appTypeDownloadStatus;

@end

@implementation SBChoosyRegister

#pragma Singleton

static SBChoosyRegister *_sharedInstance;
static dispatch_once_t once_token;

/**
 *  Singleton
 *
 *  @return Instantiates (if needed) and returns the one instance of this class
 */
+ (instancetype)sharedInstance
{
    if (_sharedInstance == nil) {
		dispatch_once(&once_token, ^ {
			_sharedInstance = [SBChoosyRegister new];
            
            // TODO: sign up for reachability updates and update all registered
            // app types whenever connection is re-established
		});
    }
	
    return _sharedInstance;
}

#pragma mark Public

- (void)registerAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    for (NSString *appType in appTypes) {
        [self registerAppTypeWithKey:appType];
    }
}

- (void)registerAppTypeKey:(NSString *)appTypeKey
{
    if (![self isAppTypeRegistered:appTypeKey]) {
        [self.registeredAppTypeKeys addObject:appTypeKey];
    }
}

- (void)registerAppTypeWithKey:(NSString *)appTypeKey
{
    __weak SBChoosyRegister *weakSelf = self;
    
    // check memory for app type
    [self findAppTypeWithKey:appTypeKey andIfFound:nil ifNotFound:^{
        // if not in memory, check file cache
        SBChoosyAppType *appType = [SBChoosyLocalStore cachedAppType:appTypeKey];
        
        // if nothing in file cache, see if it's one of the built-in types
        if (!appType) {
            appType = [SBChoosyLocalStore builtInAppType:appTypeKey];
        }
        
        if (appType) {
            if (appType.needsUpdate) {
                [weakSelf downloadAppTypeWithKey:appType.key];
            } else {
                [self addAppType:appType];
            }
        } else {
            [self downloadAppTypeWithKey:appTypeKey];
        }
        
    }];
}

- (BOOL)isAppTypeRegistered:(NSString *)appTypeKey
{
    appTypeKey = [appTypeKey lowercaseString];
    if ([self.registeredAppTypeKeys containsObject:appTypeKey]) {
        return YES;
    }
    
    return NO;
}

- (void)findAppTypeWithKey:(NSString *)appTypeKey andIfFound:(void(^)(SBChoosyAppType *appType))successBlock ifNotFound:(void(^)())failureBlock
{
    appTypeKey = [appTypeKey lowercaseString];
    [self.appTypesSerialAccessQueue addOperationWithBlock:^{
        SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
        
        if (appType) {
            if (successBlock) {
                successBlock(appType);
            }
        } else {
            if (failureBlock) {
                failureBlock(appType);
            }
        }
    }];
}

- (UIImage *)appIconForAppKey:(NSString *)appKey
{
    appKey = [appKey lowercaseString];
    
    // if the below returns nil, the icon is probably downloading still,
    // and so it will be returned via the "did download icon" delegate method later
    return [SBChoosyLocalStore appIconForAppKey:appKey];;
}

- (void)updateRegisteredAppTypes
{
    // due to multithreading, make a copy just in case there's a modification
    // to the array during the for..each loop below
    NSArray *appTypeKeys = [self.registeredAppTypeKeys copy];
    
    if (!appTypeKeys) return;
    
    __weak SBChoosyRegister *weakSelf = self;
    
    for (NSString *appTypeKey in appTypeKeys)
    {
        [self findAppTypeWithKey:appTypeKey andIfFound:^(SBChoosyAppType *appType)
        {
            if (appType.needsUpdate) {
                [weakSelf downloadAppTypeWithKey:appTypeKey];
            }
        } ifNotFound:^(void)
        {
            [self registerAppTypeWithKey:appTypeKey];
        }];
    }
}


- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    return [appType defaultApp];
}

- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey
{
    [SBChoosyLocalStore setDefaultApp:appKey forAppTypeKey:appTypeKey];
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    [SBChoosyLocalStore setLastDetectedAppKeys:[self appKeysOfApps:appType.installedApps] forAppTypeKey:appTypeKey];
}

- (void)resetDefaultAppForAppTypeKey:(NSString *)appTypeKey
{
    [SBChoosyLocalStore setDefaultApp:nil forAppTypeKey:appTypeKey];
}

#pragma mark Prvate

- (void)downloadAppTypeWithKey:(NSString *)appTypeKey
{
    BOOL isDownloadingThisType = [self isDownloadingAppType:appTypeKey];
    if (!isDownloadingThisType) {
        // see if there's fresh/more data on the server
        self.appTypeDownloadStatus[appTypeKey] = @(YES);
        NSLog(@"Downloading app type %@", appTypeKey);
        
        [SBChoosyNetworkStore downloadAppType:appTypeKey success:^(SBChoosyAppType *downloadedAppType) {
            if (downloadedAppType)
            {
                [self addAppType:downloadedAppType];
                [SBChoosyLocalStore cacheAppType:downloadedAppType];
                self.appTypeDownloadStatus[appTypeKey] = @(NO);
                
                NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to download app type with key %@, error: %@", appTypeKey, error);
            self.appTypeDownloadStatus[appTypeKey] = @(NO);
        }];
    }
}

- (void)addAppType:(SBChoosyAppType *)appTypeToAdd
{
    if (!appTypeToAdd) return;
    
    // check installed apps for this app type, and trigger app icon downloads if needed
    [appTypeToAdd takeStockOfApps];
    
    __weak SBChoosyRegister *weakSelf = self;
    [self findAppTypeWithKey:appTypeToAdd.key andIfFound:^(SBChoosyAppType *existingAppType) {
        NSInteger index = [weakSelf.appTypes indexOfObject:existingAppType];
        weakSelf.appTypes[index] = appTypeToAdd;
    } ifNotFound:^(void) {
        [weakSelf.appTypes addObject:appTypeToAdd];
    }];
}

- (BOOL)isDownloadingAppType:(NSString *)appTypeKey
{
    if ([self.appTypeDownloadStatus.allKeys containsObject:appTypeKey]) {
        return [((NSNumber *)self.appTypeDownloadStatus[appTypeKey]) boolValue];
    }
    
    return NO;
}

#pragma Helpers

- (NSArray *)appKeysOfApps:(NSArray *)apps
{
	NSMutableArray *appKeys = [NSMutableArray new];
	for (SBChoosyAppInfo *app in apps) {
		[appKeys addObject:app.appKey];
	}
	return [appKeys copy];
}

#pragma Lazy Properties


- (NSMutableArray *)appTypes
{
    if (!_appTypes) {
        _appTypes = [NSMutableArray new];
    }
    return _appTypes;
}

- (NSMutableArray *)registeredAppTypeKeys
{
    if (!_registeredAppTypeKeys) {
        _registeredAppTypeKeys = [NSMutableArray new];
    }
    return _registeredAppTypeKeys;
}

- (NSOperationQueue *)appTypesSerialAccessQueue
{
    if (!_appTypesSerialAccessQueue) {
        _appTypesSerialAccessQueue = [NSOperationQueue new];
        _appTypesSerialAccessQueue.maxConcurrentOperationCount = 1;
    }
    return _appTypesSerialAccessQueue;
}

- (NSMutableDictionary *)appTypeDownloadStatus
{
    if (!_appTypeDownloadStatus) {
        _appTypeDownloadStatus = [NSMutableDictionary new];
    }
    return _appTypeDownloadStatus;
}

@end
