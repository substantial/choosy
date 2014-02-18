
#import "SBChoosyBrainz.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "NSArray+ObjectiveSugar.h"
#import "NSDate-Utilities.h"
#import "NSString+Network.h"

@interface SBChoosyBrainz ()

@property (nonatomic) NSOperationQueue *appPreparationQueue;
@property (nonatomic) NSMutableArray *appTypes;
@property (nonatomic) NSMutableDictionary *newlyAddedApps; // since the last check
@property (nonatomic) NSMutableDictionary *newlyRemovedApps; // since the last check

@end

@implementation SBChoosyBrainz

#pragma mark - Public
#pragma mark - App Types

- (NSArray *)installedAppsForAppType:(SBChoosyAppType *)appType
{
    return [self currentAppsForType:appType];
}

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

- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock
{
    // TODO
    
    return nil;
}

#pragma mark Apps

- (void)takeStockOfApps
{
    [self detectNewApps];
    [self detectRemovedApps];
    
    NSLog(@"Newly installed apps: \n%@", [self.newlyAddedApps description]);
    NSLog(@"Newly removed apps: \n%@", [self.newlyRemovedApps description]);
}

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey
{
    NSString *defaultAppKey = [SBChoosyLocalStore defaultAppForAppType:appTypeKey];
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    SBChoosyAppInfo *defaultApp = [appType findAppInfoWithAppKey:defaultAppKey];
    
    return defaultApp;
}

- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey
{
    [SBChoosyLocalStore setDefaultApp:appKey forAppType:appTypeKey];
}

- (BOOL)isAppInstalled:(SBChoosyAppInfo *)app
{
    return [[UIApplication sharedApplication] canOpenURL:app.appURLScheme];
}

- (NSArray *)newAppsForAppType:(NSString *)appTypeKey
{
    NSArray *newApps = self.newlyAddedApps[appTypeKey];
    
    if ([newApps count] == 0) return nil;
        
    return newApps;
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

- (void)downloadDataForAppTypeIfNecessary:(NSString *)appTypeKey
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:appTypeKey];
    
    NSInteger cacheAgeInHours = [appType.dateUpdated hoursBeforeDate:[NSDate date]];
    BOOL timeToRefresh = SBCHOOSY_DEVELOPMENT_MODE == 1 || cacheAgeInHours > SBCHOOSY_UPDATE_INTERVAL || !appType.dateUpdated;
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
    [self downloadDataForAppTypeIfNecessary:appType.key];
    
    return appType.apps;
}

- (void)detectNewApps
{
    for (SBChoosyAppType *appType in self.appTypes) {
        self.newlyAddedApps[appType.key] = [self newAppsForAppType:appType givenCurrentApps:[self currentAppsForType:appType] lastDetectedAppKeys:[SBChoosyLocalStore lastDetectedAppKeysForAppTypeKey:appType.key]];
    }
}

- (void)detectRemovedApps
{
    for (SBChoosyAppType *appType in self.appTypes) {
        self.newlyRemovedApps[appType.key] = [self removedAppsForAppType:appType givenCurrentApps:[self currentAppsForType:appType] lastDetectedAppKeys:[SBChoosyLocalStore lastDetectedAppKeysForAppTypeKey:appType.key]];
    }
}

- (NSArray *)removedAppsForAppType:(SBChoosyAppType *)appType givenCurrentApps:(NSArray *)currentApps lastDetectedAppKeys:(NSArray *)lastDetectedAppKeys
{
	NSMutableArray *recentlyRemovedAppKeys = [NSMutableArray new];
	for (NSString *appKey in lastDetectedAppKeys) {
		id appMatchingKey = [[currentApps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
			return [((SBChoosyAppInfo *)evaluatedObject).appKey isEqualToString:appKey];
		}]] firstObject];
		
		if (!appMatchingKey) {
			// didn't find that app key among currently installed apps, so count the app as removed
            SBChoosyAppInfo *removedApp = [appType findAppInfoWithAppKey:appKey];
            if (removedApp) [recentlyRemovedAppKeys addObject:removedApp];
		}
	}
	
	return [recentlyRemovedAppKeys copy];
}

- (NSArray *)newAppsForAppType:(SBChoosyAppType *)appType givenCurrentApps:(NSArray *)currentApps lastDetectedAppKeys:(NSArray *)lastDetectedAppKeys
{
	NSArray *newAppKeys = [currentApps filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return ![lastDetectedAppKeys containsObject:((SBChoosyAppInfo *)evaluatedObject).appKey];
	}]];
	
	return [self appsFromAppKeys:newAppKeys forAppType:appType];
}

- (NSArray *)currentAppsForType:(SBChoosyAppType *)appType
{
	NSMutableArray *currentAppsMutable = [NSMutableArray new];
	for (SBChoosyAppInfo *app in appType.apps) {
		if ([self isAppInstalled:app]) {
			[currentAppsMutable addObject:app];
		}
	}
    
    NSArray *currentApps = [currentAppsMutable copy];
    
    [SBChoosyLocalStore setLastDetectedAppKeys:[self appKeysOfApps:currentApps] forAppTypeKey:appType.key];
	
	return currentApps;
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
        
        NSString *parameterPlaceholder = [NSString stringWithFormat:@"(%@)", appTypeParameter.key];
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

#pragma mark Lazy Properties

- (NSMutableDictionary *)newlyAddedApps
{
    if (!_newlyAddedApps) {
        _newlyAddedApps = [NSMutableDictionary new];
    }
    return _newlyAddedApps;
}

- (NSMutableDictionary *)newlyRemovedApps {
    if (!_newlyRemovedApps) {
        _newlyRemovedApps = [NSMutableDictionary new];
    }
    return _newlyRemovedApps;
}

@end
