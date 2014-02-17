
#import "SBChoosyBrainz.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "NSArray+ObjectiveSugar.h"
#import "NSDate-Utilities.h"

@interface SBChoosyBrainz ()

@property (nonatomic) NSOperationQueue *appPreparationQueue;
@property (nonatomic) NSMutableArray *appTypes;

@end

@implementation SBChoosyBrainz

#pragma mark - Public

- (NSArray *)appsForType:(NSString *)appTypeKey
{
    // check memory
    SBChoosyAppType *appType = [self findInMemoryAppType:appTypeKey];
    
    // still check if an update from the server is required; the client app could have been open for a while
    // and enough time could have passed to expire the cache.
    [self downloadDataForAppTypeIfNecessary:appTypeKey];
    
    return appType.apps;
}

- (SBChoosyAppType *)appTypeWithKey:(NSString *)appTypeKey
{
    return [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
}

- (void)prepareDataForAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    // TODO: background-thread this stuff
    
    for (NSString *appTypeKey in appTypes) {
        // check memory
        SBChoosyAppType *appType = [self findInMemoryAppType:appTypeKey];
        
        // check cache
        if (!appType) {
            appType = [SBChoosyLocalStore cachedAppType:appTypeKey];
        }
        
        // if nothing in cache, see if it's one of the built-in types
        if (!appType) {
            appType = [SBChoosyLocalStore getBuiltInAppType:appTypeKey];
            
            // serialize this info to cache so we can later mix that info with fresh data from the server
            if (appType) [SBChoosyLocalStore cacheAppTypes:@[appType]];
        }
        
        if (appType) {
            [self addAppType:appType];
        }
        
        // whether we found appType or not, check if an update from the server is required
        [self downloadDataForAppTypeIfNecessary:appTypeKey];
    }
}

- (void)downloadDataForAppTypeIfNecessary:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    BOOL timeToRefresh = YES;//[appType.createDate hoursBeforeDate:[NSDate date]] > SBCHOOSY_UPDATE_INTERVAL;
    if (!appType || timeToRefresh) {
        // see if there's fresh/more data on the server
        [SBChoosyNetworkStore downloadAppType:appTypeKey success:^(AFHTTPRequestOperation *operation, SBChoosyAppType *downloadedAppType) {
            if (downloadedAppType) {
                [self addAppType:downloadedAppType];
                [SBChoosyLocalStore cacheAppTypes:@[downloadedAppType]];
            }
        }];
    }
}

- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock
{
    // TODO
    
    return nil;
}

#pragma mark - Private

- (void)addAppType:(SBChoosyAppType *)appTypeToAdd
{
    SBChoosyAppType *existingAppType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeToAdd.key];
    
    if (!existingAppType) {
        [self.appTypes addObject:appTypeToAdd];
        
        [self.delegate didAddAppType:appTypeToAdd];
    } else {
        SBChoosyAppType *oldAppType = [existingAppType copy];
        self.appTypes[[self.appTypes indexOfObject:existingAppType]] = appTypeToAdd;
        
        [self.delegate didUpdateAppType:oldAppType withNewAppType:appTypeToAdd];
    }
}

- (NSMutableArray *)appTypes
{
    if (!_appTypes) {
        _appTypes = [NSMutableArray new];
    }
    return _appTypes;
}

- (SBChoosyAppType *)findInMemoryAppType:(NSString *)appTypeKey
{
    return [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
}

- (BOOL)isPreparationInProgress {
    return self.appPreparationQueue.operationCount > 0;
}

- (NSOperationQueue *)appPreparationQueue
{
    if (!_appPreparationQueue) {
        _appPreparationQueue = [NSOperationQueue new];
        _appPreparationQueue.maxConcurrentOperationCount = 1;
    }
    return _appPreparationQueue;
}

@end
