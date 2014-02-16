
#import "SBChoosyBrainz.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "NSArray+ObjectiveSugar.h"
#import "NSDate-Utilities.h"

@interface SBChoosyBrainz ()

@property (nonatomic) NSOperationQueue *appPreparationQueue;
@property (nonatomic) NSArray *appTypes;

@end

@implementation SBChoosyBrainz

#pragma mark - Public

- (NSArray *)appsForType:(NSString *)appTypeKey
{
    return [self appsForType:appTypeKey allowExpired:NO];
}

- (NSArray *)appsForType:(NSString *)appTypeKey allowExpired:(BOOL)allowExpired
{
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
    
    BOOL timeToRefresh = YES;//[appType.createDate hoursBeforeDate:[NSDate date]] > SBCHOOSY_UPDATE_INTERVAL && !allowExpired;
    if (!appType || timeToRefresh) {
        // see if there's fresh/more data on the server
        [SBChoosyNetworkStore downloadAppType:appTypeKey success:^(AFHTTPRequestOperation *operation, SBChoosyAppType *downloadedAppType) {
            if (downloadedAppType) [SBChoosyLocalStore cacheAppTypes:@[downloadedAppType]];
        }];
    }

    return appType.apps;
}

- (SBChoosyAppType *)appTypeWithKey:(NSString *)appTypeKey
{
    return [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
}

- (NSArray *)prepareDataForAppTypes:(NSArray *)appTypes
{
    
    // Check which of the app types are not yet in cache, or if cache is expired
    // TODO
    
    // Download data for the new/expired app types from the server
    // TODO
    NSArray *invalidAppTypes = [self downloadDataForAppTypes:appTypes];
    
    
    
    
    // Cache the data
    //[SBChoosyLocalStore cacheAppInfo:appInfo];
    
    return invalidAppTypes;
}

- (NSArray *)downloadDataForAppTypes:(NSArray *)appTypes
{
    // TODO: download from da server, convert JSON to array of SBChoosyAppInfo objects
    
    // for now, return a hard-coded list
    NSMutableArray *appInfos = [NSMutableArray new];
    
    //SBChoosyAppInfo *appInfo = [SBChoosyAppInfo]
    
    return [appInfos copy];
}

- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock
{
    
    
    return nil;
}

#pragma mark - Private

- (SBChoosyAppType *)findInMemoryAppType:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [self.appTypes detect:^BOOL(id object) {
        return ((SBChoosyAppType *)object).key == appTypeKey;
    }];
    
    return appType;
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
