
#import "SBChoosy.h"
#import "SBChoosyBrainz.h"
#import "SBChoosyActionContext.h"
#import "SBChoosyUrlBuilder.h"
#import "UIView+Helpers.h"
#import "SBChoosyPickerAppInfo.h"

@interface SBChoosy () <SBChoosyPickerDelegate>

@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyBrainz *brainz;

@property (nonatomic) SBChoosyUrlBuilder *urlBuilder;

@property (nonatomic) NSMutableArray *registeredAppTypes;

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

+ (void)registerAppType:(NSString *)appType
{
    [[SBChoosy sharedInstance] registerAppType:appType];
}

+ (void)registerAppTypes:(NSArray *)appTypes
{
    [[SBChoosy sharedInstance] registerAppTypes:appTypes];
}

+ (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] showAppPickerForAction:actionContext];
}

+ (void)prepare
{
    [[SBChoosy sharedInstance] prepare];
}

- (void)registerAppType:(NSString *)appType
{
    // TODO
    
    
}

- (void)registerAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    for (NSString *appType in appTypes) {
        [self registerAppType:appType];
    }
}

- (void)prepare
{
    // TODO
    
}
     
- (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    if (!actionContext) {
        NSLog(@"Canont show app picker b/c actionContext parameter is nil.");
    }
    
    // TODO: construct list of apps available on device
    SBChoosyPickerAppInfo *safariInfo = [[SBChoosyPickerAppInfo alloc] initWithName:@"Safari" key:@"safari" type:actionContext.appType icon:nil];
    SBChoosyPickerAppInfo *twitterInfo = [[SBChoosyPickerAppInfo alloc] initWithName:@"Twitter" key:@"twitter" type:actionContext.appType icon:nil];
    SBChoosyPickerAppInfo *tweetbotInfo = [[SBChoosyPickerAppInfo alloc] initWithName:@"Tweetbot" key:@"tweetbot" type:actionContext.appType icon:nil];
    
    // show app picker
    self.appPicker = [[SBChoosyAppPickerViewController alloc] initWithApps:@[safariInfo, twitterInfo, tweetbotInfo] actionContext:actionContext];
    self.appPicker.delegate = self;
    self.appPicker.pickerText = actionContext.appPickerText;
    self.appPicker.pickerTitle = actionContext.appType;
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

+ (void)resetAppSelectionAndShowAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    [[SBChoosy sharedInstance] resetAppSelectionAndShowAppPickerForAction:actionContext];
}

- (void)resetAppSelectionAndShowAppPickerForAction:(SBChoosyActionContext *)actionContext
{
    // TODO: erase previously remembered default app for this app type
    
    
    // re-display the picker
    [[SBChoosy sharedInstance] showAppPickerForAction:actionContext];
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

@end
