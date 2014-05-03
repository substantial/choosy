#import <UIKit/UIKit.h>
#import "ChoosyPickerDelegate.h"

@class ChoosyPickerViewModel;

@interface ChoosyAppPickerViewController : UIViewController

// designated
- (instancetype)initWithModel:(ChoosyPickerViewModel *)viewModel;

@property (nonatomic, weak) id<ChoosyPickerDelegate> delegate;

- (void)updateIconForAppKey:(NSString *)appKey withIcon:(UIImage *)appIcon;

- (void)animateAppearanceWithDuration:(NSTimeInterval)duration;
- (void)animateDisappearanceWithDuration:(NSTimeInterval)duration completion:(void(^)())block;

@end
