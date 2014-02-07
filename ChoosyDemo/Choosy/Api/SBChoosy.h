
#import <Foundation/Foundation.h>
#import "SBChoosyAppPickerViewController.h"

@class SBChoosyActionContext;

@protocol SBChoosyDelegate <NSObject>

@optional
- (void)didDownloadAppList;
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
 *  Use this to register app types on application launch. 
 *  When done registering all the app types, follow up with a call to prepare.
 *
 *  @param appType Type of the app (string).
 */
+ (void)registerAppType:(NSString *)appType;

/**
 *  Use this to register app types on application launch.
 *  When done registering all the app types, follow up with a call to prepare.
 *
 *  @param appTypes Array of strings that name the appy types used in the app.
 */
+ (void)registerAppTypes:(NSArray *)appTypes;

/**
 *  Call this after finished registering app types or UI elements.
 *  This will check if there are new app types or app types whose cache expired, etc.
 *  and will pull list of top apps for each app type. 
 *  It will then check which of these app types are installed on the device, 
 *  and it will start downloading app icons in the background as needed. 
 *  Note: a call to 'prepare' on an instance of SBChoosyRegister simply redirects here.
 *
 *  You want to either register all app types your app will need when your app loads, and call prepare here,
 *  OR just register UI elements on each related view controller using SBChoosyRegister and then call prepare on each SBChoosyRegister.
 *  It won't hurt to do both calls (they'll just execute serially), but it's entirely unnecessary to use both approaches.
 */
+ (void)prepare;

/**
 *  Manually force the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
+ (void)showAppPickerForAction:(SBChoosyActionContext *)actionContext;


/**
 *  Reset memory of favorite app for a given app type (specified in the action context), 
 *  and then force the display of app picker.
 *
 *  @param actionContext An object describing what type of app action the picker is for.
 */
+ (void)resetAppSelectionAndShowAppPickerForAction:(SBChoosyActionContext *)actionContext;

// direct actions (for manual control by the devs)
// open app selection interface

// reset app selection, then open app selection interface



@end
