
#import "Choosy.h"
#import "ChoosyGlobals.h"
#import "ChoosyAppType.h"
#import "ChoosyAppType+Protected.h"
#import "ChoosyAppInfo.h"
#import "ChoosyAppAction.h"
#import "ChoosyAppTypeParameter.h"
#import "ChoosyPickerViewModel.h"
#import "ChoosyRegister.h"
#import "NSArray+ObjectiveSugar.h"
#import "UIView+Helpers.h"
#import "UIView+Screenshot.h"
#import "NSThread+Helpers.h"
#import "ChoosyUIElementRegistration.h"
#import "ChoosyPickerViewController.h"

@interface Choosy ()

@property (nonatomic) ChoosyAppPickerViewController *appPicker;
@property (nonatomic) ChoosyRegister *appStore;
@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration

@end

@implementation Choosy {
    ChoosyActionContext *_pickerActionContext;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _allowsDefaultAppSelection = YES;
        
        [self subscribeToAppIconUpdateNotifications];
    }
    return self;
}

- (void)subscribeToAppIconUpdateNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserverForName:ChoosyDidUpdateAppIconNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification *note) {
                                    ChoosyAppInfo *app = (ChoosyAppInfo *)note.object;
                                    UIImage *appIcon = note.userInfo[@"appIcon"];
                                  
                                    if ([self.delegate respondsToSelector:@selector(didUpdateAppIcon:forApp:)]) {
                                        [self.delegate didUpdateAppIcon:appIcon forApp:app];
                                    } else {
                                        [self.appPicker updateIconForAppKey:app.appKey withIcon:appIcon];
                                    }
                              }];
}

#pragma mark - Public

// Registering means:
// Adding tap (activate) and long-press (reset default) gesture recognizers to ui element
// Adding app type to the list of registered app types, if not already there
- (void)registerUIElement:(__weak id)uiElement forAction:(ChoosyActionContext *)actionContext
{
    if (![uiElement isKindOfClass:[UIView class]]) {
        NSLog(@"Only objects inheriting from UIView can be registered. You passed ui element: %@", [uiElement description]);
    };
    
    // check if the ui element is already registered
    for (ChoosyUIElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return;
    }
    
    [[ChoosyRegister sharedInstance] registerAppTypeWithKey:actionContext.appTypeKey];
    
    // create a new registration for the ui element
    ChoosyUIElementRegistration *elementRegistration = [ChoosyUIElementRegistration new];
    elementRegistration.selectAppRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectAppEvent:)];
    elementRegistration.resetAppSelectionRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleResetAppSelectionEvent:)];
    elementRegistration.actionContext = actionContext;
    elementRegistration.uiElement = uiElement;
    
    UIControl *element = (UIControl *)uiElement;
    [element addGestureRecognizer:elementRegistration.selectAppRecognizer];
    [element addGestureRecognizer:elementRegistration.resetAppSelectionRecognizer];
    
    [self.registeredUIElements addObject:elementRegistration];
}

+ (void)registerAppTypes:(NSArray *)appTypes
{
    [[ChoosyRegister sharedInstance] registerAppTypes:appTypes];
}

- (void)handleAction:(ChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    __weak Choosy *weakSelf = self;
    [[ChoosyRegister sharedInstance] findAppTypeWithKey:actionContext.appTypeKey andIfFound:^(ChoosyAppType *appType)
    {
        // check what apps are installed
        [appType takeStockOfApps];
        
        // get app to use for this action
        ChoosyAppInfo *appInfo = [weakSelf defaultAppForAppType:appType];
        
        if (appInfo && !CHOOSY_ALWAYS_DISPLAY_PICKER) {
            // we know which app to use for the action
            [weakSelf executeAction:actionContext forAppWithKey:appInfo.appKey];
        } else {
            // we don't know, so ask user to pick an app
            [weakSelf showAppPickerForAction:actionContext appType:appType];
        }
    } ifNotFound:^{
        NSLog(@"Cannot handle action '%@', app type '%@' not found/registered.", actionContext.actionKey, actionContext.appTypeKey);
    }];
}

// TODO: rename this?
- (void)handleSelectAppEvent:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        ChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
        
        [self handleAction:elementRegistration.actionContext];
    }
}

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        ChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
        
        [self resetAppSelectionAndHandleAction:elementRegistration.actionContext];
    }
}

#pragma mark - Private

- (NSURL *)urlForAction:(ChoosyActionContext *)actionContext targetingApp:(ChoosyAppInfo *)appInfo inAppType:(ChoosyAppType *)appType
{
    // does the app support this action?
    ChoosyAppAction *action = [appInfo findActionWithKey:actionContext.actionKey];
    
    NSURL *url = [self urlForAction:action withActionParameters:actionContext.parameters appTypeParameters:appType.parameters];
    
    return url ? url : appInfo.appURLScheme;
}

- (NSURL *)urlForAction:(ChoosyAppAction *)action withActionParameters:(NSDictionary *)actionParameters appTypeParameters:(NSArray *)appTypeParameters
{
    NSMutableString *urlString = [action.urlFormat mutableCopy];
    
    for (ChoosyAppTypeParameter *appTypeParameter in appTypeParameters) {
        NSString *parameterValue = @"";
        NSString *parameterKey = [appTypeParameter.key lowercaseString];
        if ([actionParameters.allKeys containsObject:parameterKey]) {
            parameterValue = actionParameters[parameterKey];
            parameterValue = [parameterValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSString *parameterPlaceholder = [NSString stringWithFormat:@"{{%@}}", parameterKey];
        [urlString replaceOccurrencesOfString:parameterPlaceholder withString:parameterValue options:NSCaseInsensitiveSearch range:NSMakeRange(0, [urlString length])];
    }
    
    return [NSURL URLWithString:urlString];
}

#pragma mark - App Picker

- (void)showAppPickerForAction:(ChoosyActionContext *)actionContext appType:(ChoosyAppType *)appType
{
    if (!appType) {
        NSLog(@"ERROR: appType (ChoosyAppType) is nil for app type key %@", actionContext.appTypeKey);
        return;
    }
    
    NSString *keyWindowClass = NSStringFromClass([[[UIApplication sharedApplication] keyWindow] class]);
    
    // are we blocked from showing choosy due to a pop-over/alert view?
    if ([keyWindowClass isEqualToString: @"_UIAlertOverlayWindow"]) {
        // show app picker when the blocking modal window disappears
        [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidResignKeyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            [self showAppPickerForAction:actionContext appType:appType];
        }];
    } else {
        ChoosyPickerViewModel *viewModel = [self pickerViewModelForActionContext:actionContext appType:appType];
        
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
    }
}

- (ChoosyPickerViewModel *)pickerViewModelForActionContext:(ChoosyActionContext *)actionContext appType:(ChoosyAppType *)appType
{
    if (!appType) {
        return nil;
    }

    NSArray *installedApps = [appType installedApps];
    
    // now we have an array of ChoosyAppInfo objects. Use them to create the view model objects
    NSMutableArray *apps = [NSMutableArray new];
    for (ChoosyAppInfo *appInfo in installedApps) {
        ChoosyPickerAppInfo *appViewModel = [[ChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:[[ChoosyRegister sharedInstance] appIconForAppKey:appInfo.appKey]];
        [apps addObject:appViewModel];
    }
    
    ChoosyPickerViewModel *viewModel = [ChoosyPickerViewModel new];
    viewModel.appTypeInfo = [ChoosyPickerAppTypeInfo new];
    viewModel.appTypeInfo.appTypeName = appType.name;
    viewModel.appTypeInfo.installedApps = [apps copy];
    viewModel.pickerTitleText = actionContext.appPickerTitle ? actionContext.appPickerTitle : appType.name;
    if ([self.delegate respondsToSelector:@selector(textForAppPickerGivenContext:)]) {
        viewModel.pickerText = [self.delegate textForAppPickerGivenContext:actionContext];
    }
    viewModel.allowDefaultAppSelection = self.allowsDefaultAppSelection;
    
    return viewModel;
}

- (void)showDefaultPickerWithModel:(ChoosyPickerViewModel *)viewModel
{
    self.appPicker = [[ChoosyAppPickerViewController alloc] initWithModel:viewModel];
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

- (void)resetAppSelectionAndHandleAction:(ChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    // erase previously remembered default app for this app type
    [[ChoosyRegister sharedInstance] resetDefaultAppForAppTypeKey:actionContext.appTypeKey];
    
    __weak Choosy *weakSelf = self;
    [[ChoosyRegister sharedInstance] findAppTypeWithKey:actionContext.appTypeKey andIfFound:^(ChoosyAppType *appType) {
        [appType takeStockOfApps];
        
        if ([appType.installedApps count] <= 1) {
            [weakSelf showAppPickerForAction:actionContext appType:appType];
        } else {
            [weakSelf handleAction:actionContext];
        }
    } ifNotFound:^{
        NSLog(@"Could not reset app selection for app type '%@', app type not found/registered", actionContext.appTypeKey);
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
    return [Choosy topMostController];
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

- (ChoosyAppInfo *)defaultAppForAppType:(ChoosyAppType *)appType
{
    // check if new apps were installed for app type since last time default app was selected
    BOOL newAppsInstalled = [[appType.apps select:^BOOL(id object) {
        return ((ChoosyAppInfo *)object).isNew;
    }] count] > 0;
    
    ChoosyAppInfo *appToOpen = appType.defaultApp;
    
    // if default app is no longer installed or we detected new apps, don't have an app to return...
    // unless there's just one app!
    if (!appToOpen && [appType.installedApps count] == 1) {
        return appType.installedApps[0];
    }
    
    if (!appToOpen.isInstalled || newAppsInstalled)
    {
        return nil;
    }
    
    return appToOpen; // will be nil if no default app is found for this app type
}

- (void)executeAction:(ChoosyActionContext *)actionContext forAppWithKey:(NSString *)appKey
{
    __weak Choosy *weakSelf = self;
    [[ChoosyRegister sharedInstance] findAppTypeWithKey:actionContext.appTypeKey andIfFound:^(ChoosyAppType *appType)
    {
        [weakSelf executeActionContext:actionContext forAppType:appType usingAppWithKey:appKey];
    } ifNotFound:nil];
}

- (void)executeActionContext:(ChoosyActionContext *)actionContext forAppType:(ChoosyAppType *)appType usingAppWithKey:(NSString *)appKey
{
    ChoosyAppInfo *appInfo = [appType findAppInfoWithAppKey:appKey];
    
    if (!appInfo) {
        NSLog(@"The app type '%@' does not list an app with key '%@'.", appType.key, appKey);
        return;
    }
    
    // create the URL to be called
    NSURL *url = [self urlForAction:actionContext targetingApp:appInfo inAppType:appType];
    
    // call the URL
    [[UIApplication sharedApplication] openURL:url];
}

- (ChoosyUIElementRegistration *)findRegistrationInfoForUIElement:(id)uiElement
{
    for (ChoosyUIElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return elementRegistration;
    }
    return nil;
}

#pragma mark ChoosyAppPickerDelegate

- (void)didRequestPickerDismissal
{
    // close the UI
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
    [[ChoosyRegister sharedInstance] setDefaultAppForAppType:_pickerActionContext.appTypeKey withKey:appKey];
    
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
