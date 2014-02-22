
#import "SBChoosyBrainz.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyAppType+Protected.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "NSArray+ObjectiveSugar.h"
#import "NSDate-Utilities.h"
#import "NSString+Network.h"

@interface SBChoosyBrainz ()

@property (nonatomic) NSOperationQueue *appPreparationQueue;
@property (nonatomic) NSMutableArray *appTypes;

@end

@implementation SBChoosyBrainz

#pragma mark - Public
#pragma mark - App Types

- (SBChoosyAppType *)appTypeWithKey:(NSString *)appTypeKey
{
    return [self findInMemoryAppTypeByKey:appTypeKey];
}

- (void)prepareDataForAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    // TODO: background-thread this stuff
    
    for (NSString *appTypeKey in appTypes) {
        // check memory
        SBChoosyAppType *appType = [self findInMemoryAppTypeByKey:appTypeKey];
        
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
        
        if (appType) {
            [self addAppType:appType];
        }
        
        // whether we found appType or not, check if an update from the server is required
        [self downloadDataForAppTypeWithKey:appTypeKey];
    }
    
    // doesn't hurt to do this right away, to trigger app icon downloads and such
    [self takeStockOfApps];
}

- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock
{
    // TODO: promise??
    return [SBChoosyLocalStore appIconForAppKey:appKey];
}

#pragma mark Apps

- (void)takeStockOfApps
{
    for (SBChoosyAppType *appType in self.appTypes) {
        [self takeStockOfAppsForAppType:appType];
    }
}

- (void)takeStockOfAppsForAppType:(SBChoosyAppType *)appType
{
    [appType checkForInstalledApps];
    
    [appType checkForNewlyInstalledAppsGivenLastDetectedAppKeys:[SBChoosyLocalStore lastDetectedAppKeysForAppTypeWithKey:appType.key]];
    
    //        NSLog(@"Newly installed apps: \n%@", [[appType newlyAddedApps] description]);
    //        NSLog(@"Newly removed apps: \n%@", [[appType newlyRemovedApps ] description]);
    
    // check if icons need to be downloaded
    [self downloadAppIconsForAppsOfAppType:appType];
}

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    return [appType defaultApp];
}

- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey
{
    [SBChoosyLocalStore setDefaultApp:appKey forAppTypeKey:appTypeKey];
    [SBChoosyLocalStore setLastDetectedAppKeys:[self appKeysOfApps:[self findInMemoryAppTypeByKey:appTypeKey].installedApps] forAppTypeKey:appTypeKey];
}

#pragma mark URL Scheme

- (NSURL *)urlForAction:(SBChoosyActionContext *)actionContext targetingApp:(NSString *)appKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:actionContext.appTypeKey];
    SBChoosyAppInfo *app = [appType findAppInfoWithAppKey:appKey];
    
    if (!app) {
        NSLog(@"The app type '%@' does not list an app with key '%@'.", actionContext.appTypeKey, appKey);
    }
    
    // does the app support this action?
    SBChoosyAppAction *action = [app findActionWithKey:actionContext.actionKey];
    
    NSURL *url = [self urlForAction:action withActionParameters:actionContext.parameters appTypeParameters:appType.parameters];
    
    return url ? url : app.appURLScheme;
}

#pragma mark - Private
#pragma mark App Types

- (void)downloadDataForAppTypeWithKey:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    NSInteger cacheAgeInHours = [appType.dateUpdated hoursBeforeDate:[NSDate date]];
    BOOL timeToRefresh = SBCHOOSY_DEVELOPMENT_MODE == 1 || cacheAgeInHours > SBCHOOSY_UPDATE_INTERVAL || !appType.dateUpdated;
    if (!appType || timeToRefresh) {
        // see if there's fresh/more data on the server
        [SBChoosyNetworkStore downloadAppType:appTypeKey success:^(SBChoosyAppType *downloadedAppType) {
            if (downloadedAppType) {
                [self addAppType:downloadedAppType];
                [SBChoosyLocalStore cacheAppTypes:@[downloadedAppType]];
                NSLog(@"Downloaded and cached app type: %@", downloadedAppType.key);
            }
        }];
    }
}

- (void)downloadAppIconsForAppsOfAppType:(SBChoosyAppType *)appType
{
    for (SBChoosyAppInfo *app in appType.installedApps) {
        [self downloadAppIconForAppWithKey:app.appKey];
    }
}

- (void)downloadAppIconForAppWithKey:(NSString *)appKey
{
    // TODO: make this a serial queue b/c weird shit's going on otherwise
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![SBChoosyLocalStore appIconExistsForAppKey:appKey]) {
            [SBChoosyNetworkStore downloadAppIconForAppKey:appKey success:^(UIImage *appIcon)
            {
                // TODO: make sure this doesn't execute multiple times for same app key... ugh bug somewhere
                [SBChoosyLocalStore cacheAppIcon:appIcon forAppKey:appKey];
                
                // notify the delegate if it subscribed to the event
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(didDownloadAppIcon:forAppKey:)]) {
                        [self.delegate didDownloadAppIcon:appIcon forAppKey:appKey];
                    }
                });
            } failure:^(NSError *error) {
                NSLog(@"Couldn't download icon for app key %@", appKey);
            }];
        }
    });
}

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

- (SBChoosyAppType *)findInMemoryAppTypeByKey:(NSString *)appTypeKey
{
    return [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
}

#pragma mark Apps

- (NSArray *)appsForType:(SBChoosyAppType *)appType
{
    // check if an update from the server is required; the client app could have been open for a while
    // and enough time could have passed to expire the cache.
    [self downloadDataForAppTypeWithKey:appType.key];
    
    // but for now, return whatever we already have on this app type
    return appType.apps;
}

- (NSArray *)appsFromAppKeys:(NSArray *)appKeys forAppType:(SBChoosyAppType *)appType
{
    NSMutableArray *apps = [NSMutableArray new];
    for (NSString *appKey in appKeys) {
        [apps addObject:[appType findAppInfoWithAppKey:appKey]];
    }
    
    return [apps copy];
}

- (NSArray *)appKeysOfApps:(NSArray *)apps
{
	NSMutableArray *appKeys = [NSMutableArray new];
	for (SBChoosyAppInfo *app in apps) {
		[appKeys addObject:app.appKey];
	}
	return [appKeys copy];
}

#pragma mark URL Schemes

- (NSURL *)urlForAction:(SBChoosyAppAction *)action withActionParameters:(NSDictionary *)actionParameters appTypeParameters:(NSArray *)appTypeParameters
{
    NSMutableString *urlString = [action.urlFormat mutableCopy];
    
    for (SBChoosyAppTypeParameter *appTypeParameter in appTypeParameters) {
        NSString *parameterValue = @"";
        if ([actionParameters.allKeys containsObject:appTypeParameter.key]) parameterValue = actionParameters[appTypeParameter.key];
        
        NSString *parameterPlaceholder = [NSString stringWithFormat:@"{{%@}}", appTypeParameter.key];
        [urlString replaceOccurrencesOfString:parameterPlaceholder withString:parameterValue options:NSCaseInsensitiveSearch range:NSMakeRange(0, [urlString length])];
    }
    
    return [NSURL URLWithString:urlString];
}

#pragma mark Queues

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
