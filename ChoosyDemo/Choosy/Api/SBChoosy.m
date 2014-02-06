
#import "SBChoosy.h"
#import "SBChoosyBrainz.h"
#import "SBChoosyActionContext.h"
#import "SBChoosyUrlBuilder.h"
#import "UIView+Helpers.h"

@interface SBChoosyElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) SBChoosyActionContext *actionContext;

@end

@implementation SBChoosyElementRegistration

@end

@interface SBChoosy () <SBChoosyPickerDelegate>

@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration
@property (nonatomic) SBChoosyAppPickerViewController *appPicker;
@property (nonatomic) SBChoosyBrainz *brainz;

@property (nonatomic) SBChoosyUrlBuilder *urlBuilder;

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
    [[SBChoosy sharedInstance] registerUIElement:uiElement forAction:actionContext];
}

+ (void)prepareForAppTypes:(NSArray *)appTypes
{
    [[SBChoosy sharedInstance] prepareForAppTypes:appTypes];
}

// Registering means:
// Adding tap (activate) and long-press (reset default) gesture recognizers to ui element
// Adding app type to the list of registered app types, if not already there
- (void)registerUIElement:(__weak id)uiElement forAction:(SBChoosyActionContext *)actionContext
{
    if (![uiElement isKindOfClass:[UIControl class]]) {
        NSLog(@"Only objects inheriting from UIControl can be registered. You passed ui element: %@", [uiElement description]);
    };
    
    // check if the ui element is already registered
    for (SBChoosyElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return;
    }
    
    // create a new registration for the ui element
    SBChoosyElementRegistration *elementRegistration = [SBChoosyElementRegistration new];
    elementRegistration.selectAppRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelectAppEvent:)];
    elementRegistration.resetAppSelectionRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleResetAppSelectionEvent:)];
    elementRegistration.actionContext = actionContext;
    elementRegistration.uiElement = uiElement;
    
    UIControl *element = (UIControl *)uiElement;
    [element addGestureRecognizer:elementRegistration.selectAppRecognizer];
    [element addGestureRecognizer:elementRegistration.resetAppSelectionRecognizer];
    
    [self.registeredUIElements addObject:elementRegistration];
}

- (void)prepareForAppTypes:(NSArray *)appTypes
{
    // TODO
}
     
- (void)handleSelectAppEvent:(UITapGestureRecognizer *)gesture
{
    SBChoosyElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
    
    SBChoosyAppPickerAppInfo *safariInfo = [[SBChoosyAppPickerAppInfo alloc] initWithName:@"Safari" key:@"safari" type:@"Twitter" actions:nil];
    SBChoosyAppPickerAppInfo *twitterInfo = [[SBChoosyAppPickerAppInfo alloc] initWithName:@"Twitter" key:@"twitter" type:@"Twitter" actions:nil];
    SBChoosyAppPickerAppInfo *tweetbotInfo = [[SBChoosyAppPickerAppInfo alloc] initWithName:@"Tweetbot" key:@"tweetbot" type:@"Twitter" actions:nil];
    
    self.appPicker = [[SBChoosyAppPickerViewController alloc] initWithApps:@[safariInfo, twitterInfo, tweetbotInfo]];
    self.appPicker.delegate = self;
    self.appPicker.pickerText = elementRegistration.actionContext.appPickerText;
    self.appPicker.pickerTitle = elementRegistration.actionContext.appType;
    UIViewController *parentVC = [self getParentViewControllerForPicker];
    
//    [parentVC presentViewController:self.appPicker animated:YES completion:nil];
    
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

//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:elementRegistration.actionContext.appType message:@"Tapped" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//    [alert show];
    
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

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    NSLog(@"Long-pressed");
    SBChoosyElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:elementRegistration.actionContext.appType message:@"Long-pressed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    // TODO
    // delete memory of detault app for this app type
    // open App Picker UI
}

- (void)didDismissAppPicker
{
    // TODO
    // close the UI
    NSLog(@"Dismissing app picker...");
    [self dismissAppPicker];
}

- (void)didSelectApp:(NSString *)appKey
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

- (SBChoosyUrlBuilder *)urlBuilder
{
    if (!_urlBuilder) {
        _urlBuilder = [SBChoosyUrlBuilder new];
    }
    return _urlBuilder;
}

- (SBChoosyBrainz *)brainz
{
    if (!_brainz) {
        _brainz = [SBChoosyBrainz new];
    }
    return _brainz;
}

- (SBChoosyElementRegistration *)findRegistrationInfoForUIElement:(id)uiElement
{
    for (SBChoosyElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return elementRegistration;
    }
    return nil;
}

- (NSMutableArray *)registeredUIElements
{
    if (!_registeredUIElements) {
        _registeredUIElements = [NSMutableArray new];
    }
    return _registeredUIElements;
}

@end
