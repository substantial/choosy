
#import "SBCustomPickerViewController.h"

@interface SBCustomPickerViewController ()

@property (nonatomic) ChoosyPickerViewModel *viewModel;

@end

@implementation SBCustomPickerViewController

- (instancetype)initWithModel:(ChoosyPickerViewModel *)viewModel
{
    if (self = [super init]) {
        _viewModel = viewModel;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blueColor];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)]];
}

- (void)dismiss
{
    [self.delegate didDismissPicker];
}

@end
