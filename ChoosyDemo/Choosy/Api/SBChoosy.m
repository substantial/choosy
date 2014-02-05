
#import "SBChoosy.h"
#import "SBChoosyActionContext.h"

@interface SBChoosyElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) SBChoosyActionContext *actionContext;

@end

@implementation SBChoosyElementRegistration

@end

@interface SBChoosy ()

@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration


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
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:elementRegistration.actionContext.appType message:@"Tapped" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
//    SBChoosyAppPickerViewController *picker = [SBChoosyAppPickerViewController new];
//    picker.delegate = self;
}

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    NSLog(@"Long-pressed");
    SBChoosyElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:elementRegistration.actionContext.appType message:@"Long-pressed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    // TODO
    // delete memory of detaul app for this app type
    // open App Picker UI
}

- (void)didCancelAppSelection
{
    // TODO
    // close the UI
}

- (void)didSelectApp:(NSString *)appKey
{
    // TODO
    // close the UI
    // construct URL for selected app
    // call the URL
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
