
#import <Foundation/Foundation.h>

@class SBChoosyActionContext;

@protocol SBChoosyDelegate <NSObject>

@optional
- (void)didDownloadAppList;
- (void)didDownloadAppIcon:(UIImage *)appIcon forAppType:(NSString *)appType;

@end

@interface SBChoosy : NSObject

@property (nonatomic, weak) id<SBChoosyDelegate> delegate;

// register UIElement
- (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext;

// direct actions
// open app selection interface

// reset app selection, then open app selection interface

@end
