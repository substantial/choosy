
#import "SBChoosyRegister.h"
#import "SBChoosyActionContext.h"
#import "SBChoosy.h"

@interface SBChoosyUIElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) SBChoosyActionContext *actionContext;

@end

@implementation SBChoosyUIElementRegistration

@end

@interface SBChoosyRegister ()

@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration

@end

@implementation SBChoosyRegister

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


- (void)handleSelectAppEvent:(UITapGestureRecognizer *)gesture
{
    SBChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
        
    [SBChoosy showAppPickerForAction:elementRegistration.actionContext];
}

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    NSLog(@"Long-pressed");
    SBChoosyUIElementRegistration *elementRegistration = [self findRegistrationInfoForUIElement:gesture.view];
    
    [SBChoosy resetAppSelectionAndShowAppPickerForAction:elementRegistration.actionContext];
    // TODO
    // delete memory of detault app for this app type
    // open App Picker UI
}


#pragma Helpers

- (SBChoosyUIElementRegistration *)findRegistrationInfoForUIElement:(id)uiElement
{
    for (SBChoosyUIElementRegistration *elementRegistration in self.registeredUIElements) {
        if (elementRegistration.uiElement == uiElement) return elementRegistration;
    }
    return nil;
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
