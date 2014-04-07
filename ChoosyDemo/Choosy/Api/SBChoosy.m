
#import "SBChoosy.h"
#import "SBChoosyAppType.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyPickerViewModel.h"
#import "SBChoosyRegister.h"
#import "NSArray+ObjectiveSugar.h"
#import "UIView+Helpers.h"
#import "UIView+Screenshot.h"
#import "NSThread+Helpers.h"
#import "SBChoosyUIElementRegistration.h"
#import "SBChoosyPickerViewController.h"

@interface SBChoosy () <SBChoosyRegisterDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyRegister *appStore;
@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration

@end

@implementation SBChoosy {
    SBChoosyActionContext *_pickerActionContext;
}

#pragma mark - Public

// Registering means:
// Adding tap (activate) and long-press (reset default) gesture recognizers to ui element
// Adding app type to the list of registered app types, if not already there
- (void)registerUIElement:(__weak id)uiElement forAction:(SBChoosyActionContext *)actionContext
{
    if (![uiElement isKindOfClass:[UIView class]]) {
        NSLog(@"Only objects inheriting from UIView can be registered. You passed ui element: %@", [uiElement description]);
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
        // check what apps are installed
        [[SBChoosyRegister sharedInstance] takeStockOfAppsForAppType:appType];
        
        // get app to use for this action
        [weakSelf appForAction:actionContext then:^(SBChoosyAppInfo *appInfo)
        {
            if (appInfo) {
                // we know which app to use for the action
                [weakSelf executeAction:actionContext forAppWithKey:appInfo.appKey];
            } else {
                // we don't know, so ask user to pick an app
                [weakSelf showAppPickerForAction:actionContext];
            }
        }];
    }];
    
}

// TODO: rename this?
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
    [[SBChoosyRegister sharedInstance] appTypeWithKey:actionContext.appTypeKey then:^(SBChoosyAppType *appType) {
        
        SBChoosyPickerViewModel *viewModel = [self pickerViewModelForActionContext:actionContext appType:appType];
        
        [NSThread executeOnMainThread:^{
            _pickerActionContext = actionContext;
            
            // show app picker
            if ([self.delegate respondsToSelector:@selector(showCustomChoosyPickerWithModel:)]) {
                // custom picker (delegate picker UI responsibility)
                [self.delegate showCustomChoosyPickerWithModel:viewModel];
            } else {
                // show Choosy's default picker UI
                [self showDefaultPickerWithModel:viewModel];
            }
        }];
    }];
}

- (SBChoosyPickerViewModel *)pickerViewModelForActionContext:(SBChoosyActionContext *)actionContext appType:(SBChoosyAppType *)appType
{
    if (!appType) {
        return nil;
    }

    NSArray *installedApps = [appType installedApps];
    
    // now we have an array of SBChoosyAppInfo objects. Use them to create the view model objects
    NSMutableArray *apps = [NSMutableArray new];
    for (SBChoosyAppInfo *appInfo in installedApps) {
        SBChoosyPickerAppInfo *appViewModel = [[SBChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:[[SBChoosyRegister sharedInstance] appIconForAppKey:appInfo.appKey]];
        [apps addObject:appViewModel];
    }
    
    SBChoosyPickerViewModel *viewModel = [SBChoosyPickerViewModel new];
    viewModel.appTypeInfo = [SBChoosyPickerAppTypeInfo new];
    viewModel.appTypeInfo.appTypeName = appType.name;
    viewModel.appTypeInfo.installedApps = [apps copy];
    viewModel.pickerTitleText = actionContext.appPickerTitle ? actionContext.appPickerTitle : appType.name;
    if ([self.delegate respondsToSelector:@selector(textForAppPickerGivenContext:)]) {
        viewModel.pickerText = [self.delegate textForAppPickerGivenContext:actionContext];
    }
    
    return viewModel;
}

- (void)showDefaultPickerWithModel:(SBChoosyPickerViewModel *)viewModel
{
    self.appPicker = [[SBChoosyAppPickerViewController alloc] initWithModel:viewModel];
    self.appPicker.delegate = self;
    
    UIViewController *parentVC = [self getParentViewControllerForPicker];
    
    if ([self.delegate respondsToSelector:@selector(willShowDefaultChoosyPicker:)]) {
        [self.delegate willShowDefaultChoosyPicker:self.appPicker];
    }
    
    // went with this instead of [parentVC presentViewController] because a) tapping outside of the app picker works better (thanks, iOS! /s)
    // and b) iOS doesn't unload parentVC so you can see when the controller's view updates/changes.
    [self.appPicker willMoveToParentViewController:parentVC];
    [self.appPicker.view willMoveToSuperview:parentVC.view];
    
    // animate
    [parentVC addChildViewController:self.appPicker];
    [parentVC.view addSubview:self.appPicker.view];
    [self.appPicker didMoveToParentViewController:parentVC];
    
    [self.appPicker animateAppearanceWithDuration:.25f];
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
        [[SBChoosyRegister sharedInstance] takeStockOfAppsForAppType:appType];
        
        if ([appType.installedApps count] <= 1) {
            [weakSelf showAppPickerForAction:actionContext];
        } else {
            [weakSelf handleAction:actionContext];
        }
    }];
}

- (BOOL)isAppPickerShown
{
    if (self.appPicker) {
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
                return;
            }
        }
        
        if (!appToOpen.isInstalled || newAppsInstalled)
        {
            if (block) {
                block(nil);
                return;
            }
        }
        
        if (block) {
            block(appToOpen); // will be nil if no default app is found for this app type
            return;
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

#pragma mark SBChoosyRegisterDelegate

- (void)didDownloadAppIcon:(UIImage *)appIcon forApp:(SBChoosyAppInfo *)app
{
    if ([self.delegate respondsToSelector:@selector(didDownloadAppIcon:forApp:)]) {
        [self.delegate didDownloadAppIcon:appIcon forApp:app];
    }
}

#pragma mark SBChoosyAppPickerDelegate

- (void)didDismissPicker
{
    // close the UI
    NSLog(@"Dismissing app picker...");
    if ([self isAppPickerShown]) {
        [self dismissAppPickerWithCompletion:nil];
    }
}

- (void)didSelectApp:(NSString *)appKey
{
    [self dismissAppPickerWithCompletion:^{
        [self executeAction:_pickerActionContext forAppWithKey:appKey];
    }];
}

- (void)didSelectAppAsDefault:(NSString *)appKey
{
    // remember the selection
    [[SBChoosyRegister sharedInstance] setDefaultAppForAppType:_pickerActionContext.appTypeKey withKey:appKey];
    
    [self didSelectApp:appKey];
}

- (void)dismissAppPickerWithCompletion:(void(^)())completionBlock
{
    if (self.appPicker) {
        [self.appPicker willMoveToParentViewController:nil];
        
        [self.appPicker animateDisappearanceWithDuration:0.15f completion:^{
            [self.appPicker.view removeFromSuperview];
            [self.appPicker removeFromParentViewController];
            [self.appPicker didMoveToParentViewController:nil];
            self.appPicker = nil;
            
            if (completionBlock) {
                completionBlock();
            }
        }];
    } else {
        if (completionBlock) {
            completionBlock();
        }
    }
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
