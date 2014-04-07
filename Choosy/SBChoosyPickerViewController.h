#import <UIKit/UIKit.h>
#import "SBChoosyPickerDelegate.h"

@class SBChoosyPickerViewModel;

@interface SBChoosyAppPickerViewController : UIViewController

// designated
- (instancetype)initWithModel:(SBChoosyPickerViewModel *)viewModel;

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;

- (void)animateAppearanceWithDuration:(NSTimeInterval)duration;
- (void)animateDisappearanceWithDuration:(NSTimeInterval)duration completion:(void(^)())block;

@end
