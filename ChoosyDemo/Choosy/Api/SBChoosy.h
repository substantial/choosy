#import <Foundation/Foundation.h>
#import "SBChoosyAppPickerViewController.h"
#import "SBChoosyActionContext.h"

@protocol SBChoosyDelegate <NSObject>

@optional
- (void)didAddAppType:(SBChoosyAppType *)newAppType;
- (void)didUpdateAppType:(SBChoosyAppType *)existingAppType withNewAppType:(SBChoosyAppType *)updatedAppType;
- (void)didDownloadAppIcon:(UIImage *)appIcon forAppType:(NSString *)appType;

/**
 *  If your delegate is not the parent view controller, implement this method.
 *
 *  @return The view controller that will serve as parent for the App Picker view controller.
 */
- (UIViewController *)parentViewController;

@end

@interface SBChoosy : NSObject

@property (nonatomic, weak) id<SBChoosyDelegate> delegate;

/**
 *  Adds gesture recognizers to the ui element and calls Choosy with the given action context when they are triggered.
 *  Follow up with a call to Update.
 *
 *  @param uiElement     Any object that inherits from UIControl
 *  @param actionContext Action context describing the category of app to be opened, 
 *                       and optionally Action name and its Parameters.
 */
+ (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext;

/**
 *  Use this to register app types on application launch.
 *  This automatically calls Prepare, so you don't need to.
 *
 *  @param appTypes Array of strings that name the appy types used in the app.
 */
+ (void)registerAppTypes:(NSArray *)appTypes;

/**
 *  Call this after done registering app types and/or UI elements.
 *  This will download app type information as needed, including a list of apps for each app type.
 *  It will then check which of these apps are installed on the device,
 *  and it will start downloading app icons in the background (if not cached already).
 */
+ (void)update;

/**
 *  Manually cause the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
+ (void)handleAction:(SBChoosyActionContext *)actionContext;


/**
 *  Reset memory of favorite app for a given app type (specified in the action context), 
 *  and then force the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
+ (void)resetAppSelectionAndHandleAction:(SBChoosyActionContext *)actionContext;

@end
