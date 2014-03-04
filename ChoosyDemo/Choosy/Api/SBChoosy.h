#import <Foundation/Foundation.h>
#import "SBChoosyActionContext.h"
#import "SBChoosyPickerDelegate.h"

#define SBCHOOSY_DEVELOPMENT_MODE 1
#define SBCHOOSY_UPDATE_INTERVAL 24 * 3600

@class SBChoosyAppType, SBChoosyAppInfo, SBChoosyAppPickerViewController, SBChoosyPickerViewModel;

@protocol SBChoosyDelegate <NSObject>

// ALPHA CODE

@optional
//- (void)didAddApp:(SBChoosyAppInfo *)newApp;
//
//- (void)didUpdateAppInfo:(SBChoosyAppInfo *)existingAppInfo
//          withNewAppInfo:(SBChoosyAppInfo *)updatedAppInfo;

/**
 *  Implement this method if you wrote your own app picker view controller.
 *  Choosy will only show the default picker if this method is not implemented.
 *  This method is always called on the main thread.
 */
- (void)showChoosyPickerWithModel:(SBChoosyPickerViewModel *)viewModel;

/**
 *  Called right before the default picker UI is shown. 
 *  Implement this to customize view controller's view, such as font and colors.
 */
- (void)willShowChoosyDefaultPicker:(SBChoosyAppPickerViewController *)pickerViewController;

- (void)didDownloadAppIcon:(UIImage *)appIcon forApp:(SBChoosyAppInfo *)app;

- (NSString *)textForAppPickerGivenContext:(SBChoosyActionContext *)actionContext;

/**
 *  If your delegate is not the parent view controller, implement this method.
 *
 *  @return The view controller that will serve as parent for the App Picker view controller.
 */
- (UIViewController *)parentViewController;

@end

@interface SBChoosy : NSObject <SBChoosyPickerDelegate>

@property (nonatomic, weak) id<SBChoosyDelegate> delegate;

/**
 *  Adds gesture recognizers to the ui element and calls Choosy with the given action context when they are triggered.
 *  Follow up with a call to Update.
 *
 *  @param uiElement     Any object that inherits from UIControl
 *  @param actionContext Action context describing the category of app to be opened, 
 *                       and optionally Action name and its Parameters.
 */
- (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext;

/**
 *  Use this to register app types on application launch.
 *  This automatically calls Prepare, so you don't need to.
 *
 *  @param appTypes Array of strings that name the appy types used in the app.
 */
- (void)registerAppTypes:(NSArray *)appTypes;

/**
 *  Call this after done registering app types and/or UI elements.
 *  This will download app type information as needed, including a list of apps for each app type.
 *  It will then check which of these apps are installed on the device,
 *  and it will start downloading app icons in the background (if not cached already).
 */
- (void)update;

/**
 *  Manually cause the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
- (void)handleAction:(SBChoosyActionContext *)actionContext;

/**
 *  Reset memory of favorite app for a given app type (specified in the action context), 
 *  and then force the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
- (void)resetAppSelectionAndHandleAction:(SBChoosyActionContext *)actionContext;

@end

