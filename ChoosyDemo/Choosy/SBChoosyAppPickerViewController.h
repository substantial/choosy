#import <UIKit/UIKit.h>
#import "SBChoosyPickerDelegate.h"

@class SBChoosyPickerViewModel;

@interface SBChoosyAppPickerViewController : UIViewController

// designated
- (instancetype)initWithModel:(SBChoosyPickerViewModel *)viewModel;

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;

// The size of the view that doesn't include the background
@property (nonatomic, readonly) CGSize visibleSize;

@end
