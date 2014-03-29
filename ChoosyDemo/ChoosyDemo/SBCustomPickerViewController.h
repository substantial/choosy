
#import <UIKit/UIKit.h>
#import "SBChoosyPickerDelegate.h"
#import "SBChoosyPickerViewModel.h"

@interface SBCustomPickerViewController : UIViewController

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;

- (instancetype)initWithModel:(SBChoosyPickerViewModel *)viewModel;

@end
