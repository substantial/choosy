
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

+ (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext;
+ (void)prepareForAppTypes:(NSArray *)appTypes;

// direct actions (for manual control by the devs)
// open app selection interface

// reset app selection, then open app selection interface



@end
