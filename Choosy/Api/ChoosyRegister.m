
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

- (void)registerAppTypes:(NSArray *)appTypeKeys
{
    for (NSString *appTypeKey in appTypeKeys) {
        [self registerAppTypeWithKey:appTypeKey];
    }
}

- (void)registerAppTypeWithKey:(NSString *)appTypeKey
{
    appTypeKey = [appTypeKey lowercaseString];
    __weak ChoosyRegister *weakSelf = self;
    
    // check memory for app type
    [self findAppTypeWithKey:appTypeKey andIfFound:nil ifNotFound:
     ^{
        // app type not found in memory, so check cache
        ChoosyAppType *cachedAppType = [ChoosyLocalStore cachedAppType:appTypeKey];
        ChoosyAppType *builtInAppType = [ChoosyLocalStore builtInAppType:appTypeKey];
        
        // prefer info from cache, if available
        __block ChoosyAppType *appType = cachedAppType ? cachedAppType : builtInAppType;
         
        if (appType) {
            // found app type info - add it to our in-memory collection
            [self loadAppType:appType];
            
            if (appType.needsUpdate) {
                [weakSelf downloadAppTypeWithKey:appType.key success:^(ChoosyAppType *downloadedAppType) {
                    // if the app type needs an update, merge updated info with the base (not cached) info
                    // this makes sure we don't keep data that was downloaded and cached before, but was since deleted on the server
                    [builtInAppType mergeUpdatedData:downloadedAppType];
                    
                    ChoosyAppType *updatedAppType = builtInAppType ? builtInAppType : downloadedAppType;
                    updatedAppType.dateUpdated = [NSDate date];
                    
                    [weakSelf loadAppType:updatedAppType];
                    [ChoosyLocalStore cacheAppType:updatedAppType];
                }];
            }
        } else {
            [weakSelf downloadAppTypeWithKey:appTypeKey success:^(ChoosyAppType *downloadedAppType) {
                downloadedAppType.dateUpdated = [NSDate date];
                [weakSelf loadAppType:downloadedAppType];
                [ChoosyLocalStore cacheAppType:downloadedAppType];
            }];
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

- (void)registerAppTypeKey:(NSString *)appTypeKey
{
    if (![self isAppTypeRegistered:appTypeKey]) {
        [self.registeredAppTypeKeys addObject:appTypeKey];
    }
}

- (void)downloadAppTypeWithKey:(NSString *)appTypeKey success:(void(^)(ChoosyAppType* downloadedAppType))successBlock
{
    BOOL isDownloadingThisType = [self isDownloadingAppType:appTypeKey];
    if (!isDownloadingThisType) {
        // see if there's fresh/more data on the server
        self.appTypeDownloadStatus[appTypeKey] = @(YES);
        NSLog(@"Downloading app type %@", appTypeKey);
        
        [ChoosyNetworkStore downloadAppType:appTypeKey success:^(ChoosyAppType *downloadedAppType) {
            if (downloadedAppType)
            {
                if (successBlock) {
                    successBlock(downloadedAppType);
                }
                self.appTypeDownloadStatus[appTypeKey] = @(NO);
                
                NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to download app type with key %@, error: %@", appTypeKey, error);
            self.appTypeDownloadStatus[appTypeKey] = @(NO);
        }];
    }
}

- (void)loadAppType:(ChoosyAppType *)appTypeToLoad
{
    if (!appTypeToLoad) return;
    
    // check installed apps for this app type, and trigger app icon downloads if needed
    [appTypeToLoad takeStockOfApps];
    
    __weak ChoosyRegister *weakSelf = self;
    [self findAppTypeWithKey:appTypeToLoad.key andIfFound:^(ChoosyAppType *existingAppType) {
        NSInteger index = [weakSelf.appTypes indexOfObject:existingAppType];
        weakSelf.appTypes[index] = appTypeToLoad;
    } ifNotFound:^(void) {
        [weakSelf.appTypes addObject:appTypeToLoad];
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
