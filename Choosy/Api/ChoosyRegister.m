
#import "ChoosyRegister.h"
#import "ChoosyActionContext.h"
#import "Choosy.h"
#import "ChoosyLocalStore.h"
#import "ChoosyNetworkStore.h"
#import "ChoosyAppType+Protected.h"
#import "NSThread+Helpers.h"

@interface ChoosyRegister ()

@property (nonatomic) NSMutableArray *appTypes; //downloaded, processed app types
@property (nonatomic) NSMutableArray *registeredAppTypeKeys; // app types Choosy was told to care about
@property (nonatomic) NSOperationQueue *appTypesSerialAccessQueue;
@property (nonatomic) NSMutableDictionary *appTypeDownloadStatus;

@end

@implementation ChoosyRegister

#pragma Singleton

static ChoosyRegister *_sharedInstance;
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
			_sharedInstance = [ChoosyRegister new];
            
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
    __weak ChoosyRegister *weakSelf = self;
    
    // check memory for app type
    [self findAppTypeWithKey:appTypeKey andIfFound:nil ifNotFound:^{
        // if not in memory, check file cache
        ChoosyAppType *appType = [ChoosyLocalStore cachedAppType:appTypeKey];
        
        // if nothing in file cache, see if it's one of the built-in types
        if (!appType) {
            appType = [ChoosyLocalStore builtInAppType:appTypeKey];
        }
        
        if (appType) {
            // add app type we got so far to in-memory collection - download can fail
            [self addAppType:appType];
            
            if (appType.needsUpdate) {
                [weakSelf downloadAppTypeWithKey:appType.key];
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

- (void)findAppTypeWithKey:(NSString *)appTypeKey andIfFound:(void(^)(ChoosyAppType *appType))successBlock ifNotFound:(void(^)())failureBlock
{
    appTypeKey = [appTypeKey lowercaseString];
    [self.appTypesSerialAccessQueue addOperationWithBlock:^{
        ChoosyAppType *appType = [ChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
        
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
    return [ChoosyLocalStore appIconForAppKey:appKey];;
}

- (void)updateRegisteredAppTypes
{
    // due to multithreading, make a copy just in case there's a modification
    // to the array during the for..each loop below
    NSArray *appTypeKeys = [self.registeredAppTypeKeys copy];
    
    if (!appTypeKeys) return;
    
    __weak ChoosyRegister *weakSelf = self;
    
    for (NSString *appTypeKey in appTypeKeys)
    {
        [self findAppTypeWithKey:appTypeKey andIfFound:^(ChoosyAppType *appType)
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


- (ChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey
{
    ChoosyAppType *appType = [ChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    return [appType defaultApp];
}

- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey
{
    [ChoosyLocalStore setDefaultApp:appKey forAppTypeKey:appTypeKey];
    ChoosyAppType *appType = [ChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    [ChoosyLocalStore setLastDetectedAppKeys:[self appKeysOfApps:appType.installedApps] forAppTypeKey:appTypeKey];
}

- (void)resetDefaultAppForAppTypeKey:(NSString *)appTypeKey
{
    [ChoosyLocalStore setDefaultApp:nil forAppTypeKey:appTypeKey];
}

#pragma mark Prvate

- (void)downloadAppTypeWithKey:(NSString *)appTypeKey
{
    BOOL isDownloadingThisType = [self isDownloadingAppType:appTypeKey];
    if (!isDownloadingThisType) {
        // see if there's fresh/more data on the server
        self.appTypeDownloadStatus[appTypeKey] = @(YES);
        NSLog(@"Downloading app type %@", appTypeKey);
        
        [ChoosyNetworkStore downloadAppType:appTypeKey success:^(ChoosyAppType *downloadedAppType) {
            if (downloadedAppType)
            {
                [self addAppType:downloadedAppType];
                [ChoosyLocalStore cacheAppType:downloadedAppType];
                self.appTypeDownloadStatus[appTypeKey] = @(NO);
                
                NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to download app type with key %@, error: %@", appTypeKey, error);
            self.appTypeDownloadStatus[appTypeKey] = @(NO);
        }];
    }
}

- (void)addAppType:(ChoosyAppType *)appTypeToAdd
{
    if (!appTypeToAdd) return;
    
    // check installed apps for this app type, and trigger app icon downloads if needed
    [appTypeToAdd takeStockOfApps];
    
    __weak ChoosyRegister *weakSelf = self;
    [self findAppTypeWithKey:appTypeToAdd.key andIfFound:^(ChoosyAppType *existingAppType) {
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
	for (ChoosyAppInfo *app in apps) {
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
