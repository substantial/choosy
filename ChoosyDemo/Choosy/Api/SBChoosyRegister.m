
#import "SBChoosyRegister.h"
#import "SBChoosyActionContext.h"
#import "SBChoosy.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyAppType+Protected.h"

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
		});
    }
	
    return _sharedInstance;
}

#pragma mark Public


- (void)registerAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    for (NSString *appType in appTypes) {
        [self registerAppType:appType];
    }
    
    [self update];
}

- (void)registerAppType:(NSString *)appType
{
    if (![self.registeredAppTypeKeys containsObject:appType]) {
        [self.registeredAppTypeKeys addObject:appType];
    }
}

- (void)appTypeWithKey:(NSString *)appTypeKey then:(void(^)(SBChoosyAppType *appType))block
{
    [self.appTypesSerialAccessQueue addOperationWithBlock:^{
        SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
        
        if (block) {
            block(appType);
        }
    }];
}

- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock
{
    // TODO: promise??
    return [SBChoosyLocalStore appIconForAppKey:appKey];
}

- (void)update
{
    NSArray *appTypeKeys = [self.registeredAppTypeKeys copy];
    
    if (!appTypeKeys) return;
    
    for (NSString *appTypeKey in appTypeKeys) {
        // check memory
        __weak SBChoosyRegister *weakSelf = self;
        [self appTypeWithKey:appTypeKey then:^(SBChoosyAppType *appType)
         {
             // check cache
             if (!appType) {
                 appType = [SBChoosyLocalStore cachedAppType:appTypeKey];
             }
             
             // if nothing in cache, see if it's one of the built-in types
             if (!appType) {
                 appType = [SBChoosyLocalStore builtInAppType:appTypeKey];
                 
                 // serialize this info to cache so we can later mix that info with fresh data from the server
                 if (appType) [SBChoosyLocalStore cacheAppTypes:@[appType]];
             }
             
             // add the cached version to the list of app types
             if (appType) {
                 [self addAppType:appType then:^ {
                     // but go and check the server for any new app type data, if cache expired
                     [weakSelf updateDataIfNecessaryForAppTypeWithKey:appTypeKey];
                 }];
             }
         }];
    }
}

- (void)takeStockOfApps
{
    for (SBChoosyAppType *appType in self.appTypes) {
        [appType takeStockOfApps];
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

- (void)updateDataIfNecessaryForAppTypeWithKey:(NSString *)appTypeKey
{
    [self appTypeWithKey:appTypeKey then:^(SBChoosyAppType *appType)
     {
         NSDate *dateLastUpdated = appType.dateUpdated;
         NSInteger cacheAgeInHours = [[NSDate date] timeIntervalSinceDate:dateLastUpdated];
         BOOL timeToRefresh = SBCHOOSY_DEVELOPMENT_MODE == 1 || cacheAgeInHours > SBCHOOSY_UPDATE_INTERVAL || !appType.dateUpdated;
         BOOL isDownloadingThisType = [self isDownloadingAppType:appTypeKey];
         NSLog(@"timeToRefresh: %d, isDownloading: %d", timeToRefresh, isDownloadingThisType);
         if ((!appType || timeToRefresh) && !isDownloadingThisType)
         {
             //NSLog(@"Cache age is %ldx and update interval is %ldx, date is %@.", (long)cacheAgeInHours, (long)SBCHOOSY_UPDATE_INTERVAL, [dateLastUpdated description]);
             // see if there's fresh/more data on the server
             self.appTypeDownloadStatus[appTypeKey] = @(YES);
             
             [SBChoosyNetworkStore downloadAppType:appTypeKey success:^(SBChoosyAppType *downloadedAppType) {
                 if (downloadedAppType)
                 {
                     [self addAppType:downloadedAppType then:nil];
                     [SBChoosyLocalStore cacheAppTypes:@[downloadedAppType]];
                     self.appTypeDownloadStatus[appTypeKey] = @(NO);
                     
                     NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
                 }
             } failure:^(NSError *error) {
                 self.appTypeDownloadStatus[appTypeKey] = @(NO);
             }];
         }
     }];
}

- (void)addAppType:(SBChoosyAppType *)appTypeToAdd then:(void(^)())block
{
    // check installed apps for this app type, and trigger app icon downloads if needed
    [appTypeToAdd takeStockOfApps];
    
    [self appTypeWithKey:appTypeToAdd.key then:^(SBChoosyAppType *existingAppType)
     {
         [self.appTypesSerialAccessQueue addOperationWithBlock:^
          {
              if (!existingAppType) {
                  [self.appTypes addObject:appTypeToAdd];
              } else {
                  NSInteger index = [self.appTypes indexOfObject:existingAppType];
                  self.appTypes[index] = appTypeToAdd;
              }
              
              if (block) {
                  block();
              }
          }];
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
