
#import "SBChoosy.h"
#import "SBChoosyBrainz.h"
#import "UIView+Helpers.h"
#import "SBChoosyPickerAppInfo.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyRegister.h"

@interface SBChoosy () <SBChoosyPickerDelegate, SBChoosyBrainzDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyBrainz *brainz;

@property (nonatomic) NSMutableArray *registeredAppTypes;
@property (nonatomic) SBChoosyRegister *elementsRegister;

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
    if (![self.registeredAppTypes containsObject:appType]) {
        [self.registeredAppTypes addObject:appType];
    }
}

- (void)update
{
    // TODO
    [self.brainz prepareDataForAppTypes:[self.registeredAppTypes copy]];
    
    // take stock of apps
    [self.brainz takeStockOfApps];
}

- (void)handleAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    [self.brainz takeStockOfApps];
    
    SBChoosyAppInfo *appForAction = [self appForAction:actionContext];
    
    if (appForAction) {
        [self executeAction:actionContext forAppWithKey:appForAction.appKey];
        
        NSLog(@"Default app already selected: %@", appForAction.appName);
    } else {
        // ask user to pick an app
        [self showAppPickerForAction:actionContext];
    }
}

- (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    // TODO: construct list of apps available on device
    //NSMutableArray *apps = [NSMutableArray new];
    SBChoosyAppType *appType = [self.brainz appTypeWithKey:actionContext.appTypeKey];
    
    if (!appType) {
        return;
    }
    
    NSArray *installedApps = [self.brainz installedAppsForAppType:appType];
    
    // now we have an array of SBChoosyAppInfo objects. Use them to create the view model objects
    NSMutableArray *apps = [NSMutableArray new];
    for (SBChoosyAppInfo *appInfo in installedApps) {
        SBChoosyPickerAppInfo *appViewModel = [[SBChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:[self.brainz appIconForAppKey:appInfo.appKey completion:nil]];
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
    [SBChoosyLocalStore setDefaultApp:nil forAppType:actionContext.appTypeKey];
    
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
    // check if default app is already stored
    SBChoosyAppInfo *defaultApp = [self.brainz defaultAppForAppType:actionContext.appTypeKey];
    
    // check if this app is still installed
    BOOL isDefaultAppInstalled = [self.brainz isAppInstalled:defaultApp];
    
    // check if new apps were installed for app type since last time default app was selected
    BOOL newAppsInstalled = [self.brainz newAppsForAppType:actionContext.appTypeKey];
    
    if (!isDefaultAppInstalled || newAppsInstalled) {
        return nil;
    }
    
    return defaultApp; // will be nil if no default app is found for this app type
}

- (void)executeAction:(SBChoosyActionContext *)actionContext forAppWithKey:(NSString *)appKey
{
    // create the URL to be called
    NSURL *url = [self.brainz urlForAction:actionContext targetingApp:appKey];
    
    // call the URL
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark SBChoosyBrainzDelegate

- (void)didAddAppType:(SBChoosyAppType *)newAppType
{
    // TODO: update app picker UI
    
    
    [self.delegate didAddAppType:newAppType];
}

- (void)didUpdateAppType:(SBChoosyAppType *)existingAppType withNewAppType:(SBChoosyAppType *)updatedAppType
{
    // TODO: update app picker UI
    
    
    [self.delegate didUpdateAppType:existingAppType withNewAppType:updatedAppType];
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
    [self.brainz setDefaultAppForAppType:actionContext.appTypeKey withKey:appKey];
    
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

- (SBChoosyBrainz *)brainz
{
    if (!_brainz) {
        _brainz = [SBChoosyBrainz new];
        _brainz.delegate = self;
    }
    return _brainz;
}

- (NSMutableArray *)registeredAppTypes
{
    if (!_registeredAppTypes) {
        _registeredAppTypes = [NSMutableArray new];
    }
    return _registeredAppTypes;
}

- (SBChoosyRegister *)elementsRegister
{
    if (!_elementsRegister) {
        _elementsRegister = [SBChoosyRegister new];
    }
    return _elementsRegister;
}

@end
