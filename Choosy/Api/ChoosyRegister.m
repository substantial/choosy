
#import "ChoosyRegister.h"
#import "ChoosyActionContext.h"
#import "Choosy.h"
#import "ChoosyLocalStore.h"
#import "ChoosyNetworkStore.h"
#import "ChoosyAppType+Protected.h"
#import "NSThread+Helpers.h"
#import "Reachability.h"

@interface ChoosyRegister ()

@property (nonatomic) NSMutableArray *appTypes; //downloaded, processed app types
@property (nonatomic) NSMutableArray *registeredAppTypeKeys; // app types Choosy was told to care about
@property (nonatomic) dispatch_queue_t registeredKeysQueue;
@property (nonatomic) NSOperationQueue *appTypesSerialAccessQueue;
@property (nonatomic) NSMutableDictionary *appTypeDownloadStatus;

@property (nonatomic) Reachability *reachability;
@property (nonatomic) BOOL monitoringReachability; //dontcha wish Reachability itself had the flag?

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
		});
    }
	
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _registeredKeysQueue = [self createSerialQueueForKeys];
        //_reachability = [Reachability reachabilityForInternetConnection];
    }
    return self;
}

- (dispatch_queue_t)createSerialQueueForKeys
{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.choosy.registeredAppTypeKeysQueue", NULL);
    
    return serialQueue;
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf registerAppTypeKey:appTypeKey completion: ^{
            [weakSelf syncAppTypes];
        }];
    });
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

- (void)registerAppTypeKey:(NSString *)appTypeKey completion:(void(^)())completionBlock
{
    dispatch_async(self.registeredKeysQueue, ^{
        if (![self isAppTypeKeyRegistered:appTypeKey]) {
            [self.registeredAppTypeKeys addObject:appTypeKey];
        }
        
        if (completionBlock) {
            completionBlock();
        }
    });
}

- (BOOL)isAppTypeKeyRegistered:(NSString *)appTypeKey
{
    appTypeKey = [appTypeKey lowercaseString];
    if ([self.registeredAppTypeKeys containsObject:appTypeKey]) {
        return YES;
    }
    
    return NO;
}

- (void)syncAppTypes
{
    __weak ChoosyRegister *weakSelf = self;
    dispatch_async(self.registeredKeysQueue, ^{
        for (NSString *appTypeKey in weakSelf.registeredAppTypeKeys) {
            [weakSelf findAppTypeWithKey:appTypeKey andIfFound:^(ChoosyAppType *appType) {
                [weakSelf updateAppType:appType];
            } ifNotFound:^{
                [weakSelf initAppTypeWithKey:appTypeKey];
            }];
        }
    });
}

- (void)updateAppType:(ChoosyAppType *)appType
{
    if (appType.needsUpdate) {
        __weak ChoosyRegister *weakSelf = self;
        [self downloadAppTypeWithKey:appType.key success:^(ChoosyAppType *downloadedAppType) {
            // if the type has a corresponding built-in info, merge t
            ChoosyAppType *builtInAppType = [ChoosyLocalStore builtInAppType:appType.key];
            
            ChoosyAppType *mergedAppType = [weakSelf mergeUpdatedAppType:downloadedAppType withExistingAppType:builtInAppType];
            
            [weakSelf addAppTypeToRegister:mergedAppType];
            NSLog(@"Updated app type: %@", mergedAppType.key);
        }];
    }
}

- (void)initAppTypeWithKey:(NSString *)appTypeKey
{
    ChoosyAppType *cachedAppType = [ChoosyLocalStore cachedAppType:appTypeKey];
    ChoosyAppType *builtInAppType = [ChoosyLocalStore builtInAppType:appTypeKey];
    
    // prefer info from cache, if available
    __block ChoosyAppType *appType = cachedAppType ? cachedAppType : builtInAppType;
    
    if (appType) {
        // found app type info - add it to our in-memory collection
        [self loadAppType:appType];
    
        [self updateAppType:appType];
    } else {
        [self downloadAppTypeWithKey:appTypeKey success:^(ChoosyAppType *downloadedAppType) {
            downloadedAppType.dateUpdated = [NSDate date];
            [self addAppTypeToRegister:downloadedAppType];
            NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
        }];
    }
}

- (void)addAppTypeToRegister:(ChoosyAppType *)appType
{
    [self loadAppType:appType];
    [ChoosyLocalStore cacheAppType:appType];
}

- (ChoosyAppType *)mergeUpdatedAppType:(ChoosyAppType *)updatedAppType withExistingAppType:(ChoosyAppType *)existingAppType {
    [existingAppType mergeUpdatedData:updatedAppType];
    
    ChoosyAppType *mergedAppType = existingAppType ? existingAppType : updatedAppType;
    mergedAppType.dateUpdated = [NSDate date];
    
    return mergedAppType;
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
                [self stopMonitoringReachability];
                
                if (successBlock) {
                    successBlock(downloadedAppType);
                }
                self.appTypeDownloadStatus[appTypeKey] = @(NO);
                
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to download app type with key %@, error: %@", appTypeKey, error);
            [self startMonitoringReachability];
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

- (void)startMonitoringReachability
{
    if (self.monitoringReachability == YES) return;
    
    @synchronized(self) {
        if (!self.reachability) {
            self.reachability = [Reachability reachabilityWithHostname:@"raw.githubusercontent.com"];
            __weak ChoosyRegister *weakSelf = self;
            self.reachability.reachableBlock = ^(Reachability *reach) {
                [weakSelf syncAppTypes];
            };
        }
        
        [self.reachability startNotifier];
        self.monitoringReachability = YES;
    }
}

- (void)stopMonitoringReachability
{
    if (self.reachability) {
        [self.reachability stopNotifier];
        self.reachability = nil;
        self.monitoringReachability = NO;
    }
}

- (void)dealloc
{
    self.reachability = nil;
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
