
#import <UIKit/UIKit.h>
#import "ChoosyPickerDelegate.h"
#import "ChoosyPickerViewModel.h"

@interface SBCustomPickerViewController : UIViewController

@property (nonatomic, weak) id<ChoosyPickerDelegate> delegate;

- (instancetype)initWithModel:(ChoosyPickerViewModel *)viewModel;

@end
