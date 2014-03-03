
#import "SBChoosy.h"
#import "SBChoosyAppType.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyActionContext.h"
#import "SBChoosyPickerAppInfo.h"
#import "SBChoosyRegister.h"
#import "NSArray+ObjectiveSugar.h"
#import "UIView+Helpers.h"
#import "NSThread+Helpers.h"
#import "SBChoosyUIElementRegistration.h"


@interface SBChoosy () <SBChoosyPickerDelegate, SBChoosyAppTypeDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyRegister *appStore;
@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration

@end

@implementation SBChoosy

#pragma mark - Public

// Registering means:
// Adding tap (activate) and long-press (reset default) gesture recognizers to ui element
// Adding app type to the list of registered app types, if not already there
- (void)registerUIElement:(__weak id)uiElement forAction:(SBChoosyActionContext *)actionContext
{
    if (![uiElement isKindOfClass:[UIControl class]]) {
        NSLog(@"Only objects inheriting from UIControl can be registered. You passed ui element: %@", [uiElement description]);
    };
    
    // check if the ui element is already registered
    for (SBChoosyUIElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return;
    }
    
    [[SBChoosyRegister sharedInstance] registerAppTypes:@[actionContext.appTypeKey]];
    
    // create a new registration for the ui element
    SBChoosyUIElementRegistration *elementRegistration = [SBChoosyUIElementRegistration new];
    elementRegistration.selectAppRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectAppEvent:)];
    elementRegistration.resetAppSelectionRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleResetAppSelectionEvent:)];
    elementRegistration.actionContext = actionContext;
    elementRegistration.uiElement = uiElement;
    
    UIControl *element = (UIControl *)uiElement;
    [element addGestureRecognizer:elementRegistration.selectAppRecognizer];
    [element addGestureRecognizer:elementRegistration.resetAppSelectionRecognizer];
    
    [self.registeredUIElements addObject:elementRegistration];
}

- (void)registerAppTypes:(NSArray *)appTypes
{
    [[SBChoosyRegister sharedInstance] registerAppTypes:appTypes];
}

- (void)update
{
    // TODO: get rid of update altogether - update automatically on registration.
    // Just gotta make sure we don't kick off too many updates and they don't stop on each other.
    [[SBChoosyRegister sharedInstance] update];
}

- (void)handleAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    __weak SBChoosy *weakSelf = self;
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        [appType takeStockOfApps];
        
        [weakSelf appForAction:actionContext then:^(SBChoosyAppInfo *appInfo)
        {
         if (appInfo) {
             [weakSelf executeAction:actionContext forAppWithKey:appInfo.appKey];
             
             NSLog(@"Default app already selected: %@", appInfo.appName);
         } else {
             // ask user to pick an app
             [weakSelf showAppPickerForAction:actionContext];
         }
        }];
    }];
    
}

- (void)handleSelectAppEvent:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        SBChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
        
        [self handleAction:elementRegistration.actionContext];
    }
}

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        SBChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
        
        [self resetAppSelectionAndHandleAction:elementRegistration.actionContext];
    }
}

#pragma mark - Private

- (NSURL *)urlForAction:(SBChoosyActionContext *)actionContext targetingApp:(NSString *)appKey appType:(SBChoosyAppType *)appType
{
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
            parameterValue = [parameterValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        if (!appType) {
            return;
        }
    
        NSArray *installedApps = [appType installedApps];
    
        [NSThread executeOnMainThread:^{
            // now we have an array of SBChoosyAppInfo objects. Use them to create the view model objects
            NSMutableArray *apps = [NSMutableArray new];
            for (SBChoosyAppInfo *appInfo in installedApps) {
                SBChoosyPickerAppInfo *appViewModel = [[SBChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:[[SBChoosyRegister sharedInstance] appIconForAppKey:appInfo.appKey completion:nil]];
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
        }];
    }];
}

- (void)resetAppSelectionAndHandleAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    // erase previously remembered default app for this app type
    [[SBChoosyRegister sharedInstance] resetDefaultAppForAppTypeKey:actionContext.appTypeKey];
    
    __weak SBChoosy *weakSelf = self;
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        [appType takeStockOfApps];
        
        if ([appType.installedApps count] <= 1) {
            [weakSelf showAppPickerForAction:actionContext];
        } else {
            [weakSelf handleAction:actionContext];
        }
    }];
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

- (void)appForAction:(SBChoosyActionContext *)actionContext then:(void(^)(SBChoosyAppInfo *appInfo))block
{
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        // check if new apps were installed for app type since last time default app was selected
        BOOL newAppsInstalled = [[appType.apps select:^BOOL(id object) {
            return ((SBChoosyAppInfo *)object).isNew;
        }] count] > 0;
        
        SBChoosyAppInfo *appToOpen = appType.defaultApp;
        
        // if default app is no longer installed or we detected new apps, don't have an app to return...
        // unless there's just one app!
        if (!appToOpen && [appType.installedApps count] == 1) {
            if (block) {
                block(appType.installedApps[0]);
            }
        }
        
        if (!appToOpen.isInstalled || newAppsInstalled)
        {
            if (block) {
                block(nil);
            }
        }
        
        if (block) {
            block(appToOpen); // will be nil if no default app is found for this app type
        }
    }];
}

- (void)executeAction:(SBChoosyActionContext *)actionContext forAppWithKey:(NSString *)appKey
{
    __weak SBChoosy *weakSelf = self;
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        // create the URL to be called
        NSURL *url = [weakSelf urlForAction:actionContext targetingApp:appKey appType:appType];
        
        // call the URL
        [[UIApplication sharedApplication] openURL:url];
    }];
}

- (SBChoosyUIElementRegistration *)findRegistrationInfoForUIElement:(id)uiElement
{
    for (SBChoosyUIElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return elementRegistration;
    }
    return nil;
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
    if ([self isAppPickerShown]) {
        [self dismissAppPicker];
    }
}

- (void)didSelectApp:(NSString *)appKey forAction:(SBChoosyActionContext *)actionContext
{
    // remember the selection
    [[SBChoosyRegister sharedInstance] setDefaultAppForAppType:actionContext.appTypeKey withKey:appKey];
    
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

- (NSMutableArray *)registeredUIElements
{
    if (!_registeredUIElements) {
        _registeredUIElements = [NSMutableArray new];
    }
    return _registeredUIElements;
}

@end
