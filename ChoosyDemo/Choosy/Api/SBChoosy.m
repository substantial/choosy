
#import "SBChoosy.h"
#import "SBChoosyActionContext.h"

@interface SBChoosyElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) SBChoosyActionContext *actionContext;

@end

@interface SBChoosy ()

@property (nonatomic) NSMutableArray *registeredUIElements; // of type UIElementRegistration

@end

@implementation SBChoosy

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
    
    UIControl *element = (UIControl *)uiElement;
    [element addGestureRecognizer:elementRegistration.selectAppRecognizer];
    [element addGestureRecognizer:elementRegistration.resetAppSelectionRecognizer];
    
    [self.registeredUIElements addObject:elementRegistration];
}
     
- (void)handleSelectAppEvent:(UITapGestureRecognizer *)gesture
{
    SBChoosyAppPickerViewController *picker = [SBChoosyAppPickerViewController new];
    picker.delegate = self;
}

- (void)handleResetAppSelectionEvent:(UILongPressGestureRecognizer *)gesture
{
    
}


- (void)didCancelAppSelection
{
    
}

- (void)didSelectApp:(NSString *)appKey
{
    
}

- (NSMutableArray *)registeredUIElements
{
    if (!_registeredUIElements) {
        _registeredUIElements = [NSMutableArray new];
    }
    return _registeredUIElements;
}

@end
