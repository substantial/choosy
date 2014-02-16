
#import "SBChoosy.h"
#import "SBChoosyBrainz.h"
#import "SBChoosyUrlBuilder.h"
#import "UIView+Helpers.h"
#import "SBChoosyPickerAppInfo.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyRegister.h"

@interface SBChoosy () <SBChoosyPickerDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyBrainz *brainz;

@property (nonatomic) SBChoosyUrlBuilder *urlBuilder;

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

+ (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext
{
    if (!actionContext || !uiElement) return;
    
    [[SBChoosy sharedInstance] registerAppType:actionContext.appTypeKey];
    [[SBChoosy sharedInstance].elementsRegister registerUIElement:uiElement forAction:actionContext];
}

+ (void)registerAppType:(NSString *)appType
{
    [[SBChoosy sharedInstance] registerAppType:appType];
}


- (void)registerAppType:(NSString *)appType
{
    if (![self.registeredAppTypes containsObject:appType]) {
        [self.registeredAppTypes addObject:appType];
    }
}

+ (void)registerAppTypes:(NSArray *)appTypes
{
    [[SBChoosy sharedInstance] registerAppTypes:appTypes];
}

- (void)registerAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    for (NSString *appType in appTypes) {
        [self registerAppType:appType];
    }
}

+ (void)prepare
{
    [[SBChoosy sharedInstance] prepare];
}

- (void)prepare
{
    // TODO
    NSArray *badAppTypes = [self.brainz prepareDataForAppTypes:[self.registeredAppTypes copy]];
    
    for (NSString *badAppType in badAppTypes) {
        NSLog(@"'%@' is not a valid app type. Make sure you spelt it correctly!", badAppType);
        [self.registeredAppTypes removeObject:badAppType];
    }
}

+ (void)handleAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] handleAction:actionContext];
}
     
- (void)handleAction:(SBChoosyActionContext *)actionContext
{
    if ([self isAppPickerShown]) return;
    
    if (!actionContext) {
        NSLog(@"Cannot show app picker b/c actionContext parameter is nil.");
    }
    
    // check if default app is already stored
    NSString *defaultAppKey = [SBChoosyLocalStore defaultAppForAppType:actionContext.appTypeKey];
    
    if (defaultAppKey) {
        // TODO
        // perform the action on the default app
        NSLog(@"Default app already selected: %@", defaultAppKey);
    } else {
        // ask user to pick an app
        [self showAppPickerForAction:actionContext];
    }
}

- (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    // TODO: construct list of apps available on device
    //NSMutableArray *apps = [NSMutableArray new];
    NSArray *appInfos = [self.brainz appsForType:actionContext.appTypeKey];
    SBChoosyAppType *appType = [self.brainz appTypeWithKey:actionContext.appTypeKey];
    
    // now we have an array of SBChoosyAppInfo objects. Use them to create the view model objects
    NSMutableArray *apps = [NSMutableArray new];
    for (SBChoosyAppInfo *appInfo in appInfos) {
        SBChoosyPickerAppInfo *appViewModel = [[SBChoosyPickerAppInfo alloc] initWithName:appInfo.appName key:appInfo.appKey icon:nil];
        [apps addObject:appViewModel];
    }

//    if ([[actionContext.appType lowercaseString] isEqualToString: @"twitter"]) {
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Safari" key:@"safari" type:actionContext.appType icon:nil]];
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Twitter" key:@"twitter" type:actionContext.appType icon:nil]];
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Tweetbot" key:@"tweetbot" type:actionContext.appType icon:nil] ];
//    } else {
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Mail" key:@"mail" type:actionContext.appType icon:nil]];
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Gmail" key:@"googlemail" type:actionContext.appType icon:nil]];
//        [apps addObject: [[SBChoosyPickerAppInfo alloc] initWithName:@"Mailbox" key:@"mailbox" type:actionContext.appType icon:nil]];
//    }
    
    // show app picker
    self.appPicker = [[SBChoosyAppPickerViewController alloc] initWithApps:[apps copy] actionContext:actionContext appTypeName:appType.name];
    self.appPicker.delegate = self;
    self.appPicker.pickerText = actionContext.appPickerText;
    self.appPicker.pickerTitle = actionContext.appTypeKey;
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

+ (void)resetAppSelectionAndHandleAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] resetAppSelectionAndShowAppPickerForAction:actionContext];
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

#pragma Private

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
    // TODO
    
    // remember the selection
    [SBChoosyLocalStore setDefaultApp:appKey forAppType:actionContext.appTypeKey];
    
    // close the UI
    [self dismissAppPicker];
    
    
    
    // construct URL for selected app
//    NSString *finalURL = self.urlBuilder
    
    // call the URL
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
    }
    return _brainz;
}

- (SBChoosyUrlBuilder *)urlBuilder
{
    if (!_urlBuilder) {
        _urlBuilder = [SBChoosyUrlBuilder new];
    }
    return _urlBuilder;
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
