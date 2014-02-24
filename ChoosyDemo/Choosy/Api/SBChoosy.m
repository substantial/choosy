
#import "SBChoosy.h"
#import "SBChoosyAppType.h"
#import "SBChoosyAppType+Protected.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyPickerAppInfo.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyRegister.h"
#import "NSArray+ObjectiveSugar.h"
#import "UIView+Helpers.h"
#import "NSDate-Utilities.h"
#import "NSString+Network.h"

@interface SBChoosy () <SBChoosyPickerDelegate, SBChoosyAppTypeDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyRegister *elementsRegister;

@property (nonatomic) NSMutableArray *registeredAppTypeKeys; // app types Choosy was told to care about
@property (nonatomic) NSMutableArray *appTypes; //downloaded, processed app types

@property (nonatomic) NSOperationQueue *appTypesSerialAccessQueue;
@property (nonatomic) NSMutableDictionary *appTypeDownloadStatus;

@end

@implementation SBChoosy

#pragma mark Singleton

static SBChoosy *_sharedInstance;
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
			_sharedInstance = [SBChoosy new];
		});
    }
	
    return _sharedInstance;
}

#pragma mark - Public

+ (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext
{
    if (!actionContext || !uiElement) return;
    
    [[SBChoosy sharedInstance] registerAppType:actionContext.appTypeKey];
    [[SBChoosy sharedInstance].elementsRegister registerUIElement:uiElement forAction:actionContext];
}

+ (void)registerAppTypes:(NSArray *)appTypes
{
    [[SBChoosy sharedInstance] registerAppTypes:appTypes];
}

+ (void)update
{
    [[SBChoosy sharedInstance] update];
}

+ (void)handleAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] handleAction:actionContext];
}

+ (void)resetAppSelectionAndHandleAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] resetAppSelectionAndShowAppPickerForAction:actionContext];
}

#pragma mark - Private
#pragma mark Picker

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

- (void)update
{
    NSArray *appTypeKeys = [self.registeredAppTypeKeys copy];
    
    if (!appTypeKeys) return;
    
    for (NSString *appTypeKey in appTypeKeys) {
        // check memory
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
                __weak SBChoosy *weakSelf = self;
                [self addAppType:appType then:^ {
                    // but go and check the server for any new app type data, if cache expired
                    [weakSelf updateDataIfNecessaryForAppTypeWithKey:appTypeKey];
                }];
            }
        }];
    }
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
                
                [self.delegate didAddAppType:appTypeToAdd];
            } else {
                SBChoosyAppType *oldAppType = [existingAppType copy];
                
                NSInteger index = [self.appTypes indexOfObject:existingAppType];
                self.appTypes[index] = appTypeToAdd;
                
                if ([self.delegate respondsToSelector:@selector(didUpdateAppType:withNewAppType:)]) {
                    [self.delegate didUpdateAppType:oldAppType withNewAppType:appTypeToAdd];
                }
            }
            
            if (block) {
                block();
            }
        }];
    }];
}

- (void)takeStockOfApps
{
    for (SBChoosyAppType *appType in self.appTypes) {
        [appType takeStockOfApps];
    }
}

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

- (BOOL)isDownloadingAppType:(NSString *)appTypeKey
{
    if ([self.appTypeDownloadStatus.allKeys containsObject:appTypeKey]) {
        return [((NSNumber *)self.appTypeDownloadStatus[appTypeKey]) boolValue];
    }
    
    return NO;
}

- (void)appTypeWithKey:(NSString *)appTypeKey then:(void(^)(SBChoosyAppType *))block
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

- (void)handleAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:actionContext.appTypeKey];
    
    [appType takeStockOfApps];
    
    SBChoosyAppInfo *appForAction = [self appForAction:actionContext];
    
    if (appForAction) {
        [self executeAction:actionContext forAppWithKey:appForAction.appKey];
        
        NSLog(@"Default app already selected: %@", appForAction.appName);
    } else {
        // ask user to pick an app
        [self showAppPickerForAction:actionContext];
    }
}

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

- (NSURL *)urlForAction:(SBChoosyAppAction *)action withActionParameters:(NSDictionary *)actionParameters appTypeParameters:(NSArray *)appTypeParameters
{
    NSMutableString *urlString = [action.urlFormat mutableCopy];
    
    for (SBChoosyAppTypeParameter *appTypeParameter in appTypeParameters) {
        NSString *parameterValue = @"";
        if ([actionParameters.allKeys containsObject:appTypeParameter.key]) {
            parameterValue = actionParameters[appTypeParameter.key];
            parameterValue = [parameterValue urlEncodeUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSString *parameterPlaceholder = [NSString stringWithFormat:@"{{%@}}", appTypeParameter.key];
        [urlString replaceOccurrencesOfString:parameterPlaceholder withString:parameterValue options:NSCaseInsensitiveSearch range:NSMakeRange(0, [urlString length])];
    }
    
    return [NSURL URLWithString:urlString];
}

#pragma mark - App Picker

- (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    // TODO: construct list of apps available on device
    //NSMutableArray *apps = [NSMutableArray new];
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:actionContext.appTypeKey];
    
    if (!appType) {
        return;
    }
    
    NSArray *installedApps = [appType installedApps];
    
    // now we have an array of SBChoosyAppInfo objects. Use them to create the view model objects
    NSMutableArray *apps = [NSMutableArray new];
    for (SBChoosyAppInfo *appInfo in installedApps) {
        SBChoosyPickerAppInfo *appViewModel = [[SBChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:[self appIconForAppKey:appInfo.appKey completion:nil]];
        [apps addObject:appViewModel];
    }
    
    // show app picker
    self.appPicker = [[SBChoosyAppPickerViewController alloc] initWithApps:[apps copy] actionContext:actionContext appTypeName:appType.name];
    self.appPicker.delegate = self;
    if ([self.delegate respondsToSelector:@selector(textForAppPickerGivenContext:)]) {
        self.appPicker.pickerText = [self.delegate textForAppPickerGivenContext:actionContext];
    }
    self.appPicker.pickerTitle = actionContext.appPickerTitle ? actionContext.appPickerTitle : appType.name;
    UIViewController *parentVC = [self getParentViewControllerForPicker];
    
    // went with this instead of [parentVC presentViewController] because a) tapping outside of the app picker works better (thanks, iOS! /s)
    // and b) iOS doesn't unload parentVC so you can see when the controller's view updates/changes.
    [self.appPicker willMoveToParentViewController:parentVC];
	[self.appPicker.view willMoveToSuperview:parentVC.view];
    
	// TODO: add blurred background layer
//	self.blurredLayer = [[UIImageView alloc] initWithImage:self.blurredAboutPage];
//	self.blurredLayer.alpha = 0;
//	[parentVC.view addSubview:self.blurredLayer];
	
	// animate
	CGFloat midX = parentVC.view.width / 2.0f;
	self.appPicker.view.center = CGPointMake(midX, parentVC.view.height + self.appPicker.visibleSize.height / 2.0f);
	[parentVC.view addSubview:self.appPicker.view];
	[UIView animateWithDuration:0.5f animations:^{
//		self.blurredLayer.alpha = 1;
		self.appPicker.view.center = CGPointMake(midX, parentVC.view.height / 2.0f);
	} completion:^(BOOL finished) {
		[self.appPicker didMoveToParentViewController:parentVC];
	}];
}

- (void)resetAppSelectionAndShowAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    // erase previously remembered default app for this app type
    [SBChoosyLocalStore setDefaultApp:nil forAppTypeKey:actionContext.appTypeKey];
    
    [self handleAction:actionContext];
}

- (BOOL)isAppPickerShown
{
    if (self.appPicker && self.appPicker.parentViewController) {
        return YES;
    }
    
    return NO;
}

- (UIViewController *)getParentViewControllerForPicker
{
    if ([self.delegate respondsToSelector:@selector(parentViewController)]) {
        UIViewController *parentVC = [self.delegate parentViewController];
        if (parentVC) return parentVC;
    }
    
    // otherwise see if the delegate itself inherits from UIViewController
    if ([self.delegate isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.delegate;
    }
    
    // still no parent VC found? Use the top VC in the key window
    return [SBChoosy topMostController];
}
     
+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark Default App and App Detection

- (SBChoosyAppInfo *)appForAction:(SBChoosyActionContext *)actionContext
{
    SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:self.appTypes byKey:actionContext.appTypeKey];
    
    // check if new apps were installed for app type since last time default app was selected
    BOOL newAppsInstalled = [[appType.apps select:^BOOL(id object) {
        return ((SBChoosyAppInfo *)object).isNew;
    }] count] > 0;
    
    SBChoosyAppInfo *appToOpen = appType.defaultApp;
    
    // if default app is no longer installed or we detected new apps, don't have an app to return...
    // unless there's just one app!
    if (!appToOpen.isInstalled || newAppsInstalled)
    {
        if (!appToOpen && [appType.installedApps count] == 1) {
            return appType.installedApps[0];
        } else {
            return nil;
        }
    }
    
    return appToOpen; // will be nil if no default app is found for this app type
}

- (void)executeAction:(SBChoosyActionContext *)actionContext forAppWithKey:(NSString *)appKey
{
    // create the URL to be called
    NSURL *url = [self urlForAction:actionContext targetingApp:appKey];
    
    // call the URL
    [[UIApplication sharedApplication] openURL:url];
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

- (NSArray *)appKeysOfApps:(NSArray *)apps
{
	NSMutableArray *appKeys = [NSMutableArray new];
	for (SBChoosyAppInfo *app in apps) {
		[appKeys addObject:app.appKey];
	}
	return [appKeys copy];
}

#pragma mark SBChoosyAppTypeDelegate

- (void)didDownloadAppIcon:(UIImage *)appIcon forApp:(SBChoosyAppInfo *)app
{
    if ([self.delegate respondsToSelector:@selector(didDownloadAppIcon:forApp:)]) {
        [self.delegate didDownloadAppIcon:appIcon forApp:app];
    }
}

#pragma mark SBChoosyAppPickerDelegate

- (void)didDismissAppPicker
{
    // TODO
    // close the UI
    NSLog(@"Dismissing app picker...");
    [self dismissAppPicker];
}

- (void)didSelectApp:(NSString *)appKey forAction:(SBChoosyActionContext *)actionContext
{
    // remember the selection
    [self setDefaultAppForAppType:actionContext.appTypeKey withKey:appKey];
    
    // close the UI
    [self dismissAppPicker];
    
    [self executeAction:actionContext forAppWithKey:appKey];
}

- (void)dismissAppPicker
{
	[self.appPicker willMoveToParentViewController:nil];
	
	[UIView animateWithDuration:0.5f animations:^ {
//		self.blurredLayer.alpha = 0;
		self.appPicker.view.center = CGPointMake(self.appPicker.view.center.x, self.appPicker.view.center.y + self.appPicker.view.width);
	}completion:^(BOOL finished) {
		[self.appPicker.view removeFromSuperview];
		[self.appPicker didMoveToParentViewController:nil];
		self.appPicker = nil;
	}];
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

- (SBChoosyRegister *)elementsRegister
{
    if (!_elementsRegister) {
        _elementsRegister = [SBChoosyRegister new];
    }
    return _elementsRegister;
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
