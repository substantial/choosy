

#import <UIKit/UIKit.h>
#import "SBChoosyAppInfo.h"

@class SBChoosyActionContext;
@class SBChoosyPickerAppInfo;

@protocol SBChoosyPickerDelegate <NSObject>

@required
- (void)didDismissAppPicker;
- (void)didSelectApp:(NSString *)appKey forAction:(SBChoosyActionContext *)actionContext;

@end

@interface SBChoosyAppPickerViewController : UIViewController

// designated
- (instancetype)initWithApps:(NSArray *)apps actionContext:(SBChoosyActionContext *)actionContext;

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;
@property (nonatomic) NSString *pickerTitle;
@property (nonatomic) NSString *pickerText;

@property (nonatomic, readonly) NSArray *apps;
@property (nonatomic, readonly) SBChoosyActionContext *actionContext;

// The size of the view that doesn't include the background
@property (nonatomic) CGSize visibleSize;

@end
