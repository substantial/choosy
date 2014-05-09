#import <Foundation/Foundation.h>
#import "ChoosyActionContext.h"
#import "ChoosyPickerDelegate.h"

@class ChoosyAppType, ChoosyAppInfo, ChoosyAppPickerViewController, ChoosyPickerViewModel;

@protocol ChoosyDelegate <NSObject>

@optional
/**
 *  Implement this method if you wrote your own app picker view controller.
 *  Choosy will only show the default picker if this method is not implemented.
 *  This method is always called on the main thread.
 */
- (void)showCustomChoosyPickerWithModel:(ChoosyPickerViewModel *)viewModel;

/**
 *  Called right before the default picker UI is shown. 
 *  Implement this to customize view controller's view, such as font and colors.
 */
- (void)willShowDefaultChoosyPicker:(ChoosyAppPickerViewController *)pickerViewController;

/**
 *  Called when a new app icon has been downloaded
 *
 *  @param appIcon The new icon
 *  @param app     Related app object
 */
- (void)didUpdateAppIcon:(UIImage *)appIcon forApp:(ChoosyAppInfo *)app;

- (NSString *)textForAppPickerGivenContext:(ChoosyActionContext *)actionContext;

/**
 *  If your delegate is not the parent view controller, implement this method.
 *
 *  @return The view controller that will serve as parent for the App Picker view controller.
 */
- (UIViewController *)parentViewController;

@end

@interface Choosy : NSObject <ChoosyPickerDelegate>

@property (nonatomic, weak) id<ChoosyDelegate> delegate;

/**
 *  Set this to NO if you want to always display app picker and remove default app selection affordances in the default picker.
 *  Default value is YES.
 */
@property (nonatomic) BOOL allowsDefaultAppSelection;

/**
 *  Adds gesture recognizers to the ui element and calls Choosy with the given action context when they are triggered.
 *  Follow up with a call to Update.
 *
 *  @param uiElement     Any object that inherits from UIControl
 *  @param actionContext Action context describing the category of app to be opened, 
 *                       and optionally Action name and its Parameters.
 */
- (void)registerUIElement:(id)uiElement forAction:(ChoosyActionContext *)actionContext;

/**
 *  Use this to register app types on application launch.
 *  This automatically calls Prepare, so you don't need to.
 *
 *  @param appTypes Array of strings that name the appy types used in the app.
 */
+ (void)registerAppTypes:(NSArray *)appTypes;

/**
 *  Manually cause the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
- (void)handleAction:(ChoosyActionContext *)actionContext;

/**
 *  Reset memory of favorite app for a given app type (specified in the action context), 
 *  and then force the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
- (void)resetAppSelectionAndHandleAction:(ChoosyActionContext *)actionContext;

@end

