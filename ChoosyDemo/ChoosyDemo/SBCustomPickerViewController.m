
#import "SBCustomPickerViewController.h"

@interface SBCustomPickerViewController ()

@property (nonatomic) SBChoosyPickerViewModel *viewModel;

@end

@implementation SBCustomPickerViewController

- (instancetype)initWithModel:(SBChoosyPickerViewModel *)viewModel
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
