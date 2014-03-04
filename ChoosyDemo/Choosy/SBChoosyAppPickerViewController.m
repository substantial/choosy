#import "SBChoosyAppPickerViewController.h"
#import "UIView+Helpers.h"
#import "SBChoosyPickerViewModel.h"
#import "SBChoosyPickerView.h"

@interface SBChoosyAppCell : UICollectionViewCell

@property (nonatomic) SBChoosyPickerAppInfo *appInfo;

@end

@interface SBChoosyAppPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) SBChoosyPickerViewModel *viewModel;

@property (nonatomic) UIView *contentArea; // this is the whole visible part
@property (nonatomic) UIView *appRow; // this is just the row showing app icons
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIView *titleView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIView *backgroundView;

@end

@implementation SBChoosyAppPickerViewController

static CGFloat _appIconHeight = 60;
static CGFloat _appIconWidth = 60;
static CGFloat _appsRowLeftPadding = 5;
static CGFloat _appsRowGapBetweenApps = 10;

- (instancetype)initWithModel:(SBChoosyPickerViewModel *)viewModel
{
    if (self = [super init]) {
		_viewModel = viewModel;
		[self initialize];
	}
	return self;
}

- (void)initialize {
	self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
//    self.backgroundView.userInteractionEnabled = YES;
//    self.backgroundView.backgroundColor = [UIColor colorWithRed:0.8 green:0.5 blue:0.5 alpha:1];
//    [self.view addSubview:self.backgroundView];
//    NSLog(@"background view size: %@", NSStringFromCGRect(self.backgroundView.frame));
    
    // this be holding all the content except blurred background
	UIColor *backgroundColor = [UIColor colorWithRed:23/255.0f green:24/255.0f blue:25/255.0f alpha:1];
	CGFloat appsRowTitleTextTopPadding = 17;
	
	// Doing label first so I can measure height of text afterwards
	UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
	collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	UIEdgeInsets collectionViewContentInset = UIEdgeInsetsMake(0, _appsRowLeftPadding, 0, _appsRowLeftPadding);
	
	CGFloat spacingBetweenApps = collectionViewLayout.minimumInteritemSpacing;
	if (_appsRowGapBetweenApps > spacingBetweenApps) spacingBetweenApps = _appsRowGapBetweenApps;
	
	CGFloat openWithXOffset = collectionViewContentInset.left / 2.0f + spacingBetweenApps / 2.0f;
	UILabel *appListSectionTitle = [[UILabel alloc] initWithFrame:CGRectMake(openWithXOffset, appsRowTitleTextTopPadding, self.view.width - openWithXOffset, 20)];
    NSString *pickerText = self.viewModel.pickerText ? self.viewModel.pickerText : NSLocalizedString(@"Pick your favorite app...", @"'Pick your favorite app...' app picker text");
	appListSectionTitle.text = pickerText;
	appListSectionTitle.font = [UIFont systemFontOfSize:13];
	appListSectionTitle.textColor = [UIColor whiteColor];
	[appListSectionTitle sizeToFit];
	
	CGFloat separatorLineHeight = 1;
	CGFloat appsCollectionViewHeight = _appIconHeight * 2.0f;
	CGFloat appsRowHeight = appsCollectionViewHeight + appsRowTitleTextTopPadding + appListSectionTitle.height + separatorLineHeight;
	CGFloat titleHeight = 35;
	CGFloat contentAreaHeight = titleHeight + appsRowHeight;
	
	self.contentArea = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, contentAreaHeight)]; // will size to fit/be positioned at the end
	self.contentArea.backgroundColor = backgroundColor;
	
	self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentArea.width, titleHeight)];
	self.titleView.backgroundColor = [UIColor clearColor];
	self.titleLabel = [[UILabel alloc] initWithFrame:self.titleView.bounds];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.font = [UIFont systemFontOfSize:16];
	self.titleLabel.text = self.viewModel.pickerTitleText;
	self.titleLabel.textColor = [UIColor colorWithRed:123/255.0f green:123/255.0f blue:123/255.0f alpha:1];
	[self.titleView addSubview:self.titleLabel];
	
//	self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	self.closeButton.titleLabel.text =
//	self.closeButton.alpha = 0.5f;
//	self.closeButton.frame = CGRectMake(self.titleView.width - MIN_TAP_AREA_WIDTH, 0, MIN_TAP_AREA_WIDTH, self.titleView.height);
//	[self.closeButton addTarget:self.delegate action:@selector(didDismissSharingSheet) forControlEvents:UIControlEventTouchUpInside];
//	[self.titleView addSubview:self.closeButton];
	
	// add apps row
	self.appRow = [[UIView alloc] initWithFrame:CGRectMake(0, self.titleView.height, self.view.width, appsRowHeight)];
	self.appRow.backgroundColor = backgroundColor;
	
	// line separator
	UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 1)];
	lineSeparator.backgroundColor = [UIColor colorWithRed:48/255.0f green:48/255.0f blue:48/255.0f alpha:1];
	[self.appRow addSubview:lineSeparator];
	[self.appRow addSubview:appListSectionTitle];
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.appRow.height - appsCollectionViewHeight, self.appRow.width, appsCollectionViewHeight) collectionViewLayout:collectionViewLayout];
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	self.collectionView.backgroundColor = [UIColor clearColor];
	self.collectionView.pagingEnabled = NO;
	[self.collectionView registerClass:[SBChoosyAppCell class] forCellWithReuseIdentifier:@"cell"];
	self.collectionView.contentInset = collectionViewContentInset;
	
	//NSLog(@"Content inset: %@, Content offset: %@, section inset: %@, interitem spacing: %d", NSStringFromUIEdgeInsets(self.collectionView.contentInset), NSStringFromCGPoint(self.collectionView.contentOffset), NSStringFromUIEdgeInsets(((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).sectionInset), (int)((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).minimumInteritemSpacing);
	
	[self.contentArea addSubview:self.appRow];
	[self.contentArea addSubview:self.titleView];
	[self.appRow addSubview:self.collectionView];
	
	[self.view addSubview:self.contentArea];
    NSLog(@"app picker view size: %@", NSStringFromCGRect(self.view.frame));
	
	[self.contentArea sizeToFit];
	self.contentArea.center = CGPointMake(self.view.width / 2.0f, self.view.height - self.contentArea.height / 2.0f);
	
	//[self.backgroundView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(viewSwiped:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
	[self.view addGestureRecognizer:swipeDown];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	//NSLog( @"Collection view fram: %@", NSStringFromCGRect(self.collectionView.frame) );
}

- (void)setPickerTitle:(NSString *)pickerTitle
{
    self.titleLabel.text = pickerTitle;
}

- (void)setTitleToDisplay:(NSString *)titleToDisplay
{
	self.titleLabel.text = titleToDisplay;
}

- (CGSize)visibleSize
{
	return self.contentArea.bounds.size;
}

#pragma Gestures

- (void)viewTapped:(UITapGestureRecognizer *)gesture
{
	CGPoint point = [gesture locationInView:self.view];
	
	if (!CGRectContainsPoint(self.contentArea.frame, point)) {
		// tapped outside of sharing sheet - interpret as dismiss
		[self.delegate didDismissPicker];
	}
}

- (void)viewSwiped:(UISwipeGestureRecognizer *)gesture
{
	if ((gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateRecognized) && gesture.direction == UISwipeGestureRecognizerDirectionDown) {
		// interpret swipe down as dismiss
		[self.delegate didDismissPicker];
	}
}

- (void)appTapped:(UITapGestureRecognizer *)gesture
{
	SBChoosyAppCell *cell = (SBChoosyAppCell *)gesture.view;
	
	NSString *appKey = cell.appInfo.appKey;
    
    NSLog(@"Picked app %@", cell.appInfo.appName);
	
	[self.delegate didSelectApp:appKey];
}

#pragma mark Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return (NSInteger)[self.viewModel.appTypeInfo.installedApps count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	SBChoosyAppCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
	
	cell.appInfo = self.viewModel.appTypeInfo.installedApps[(NSUInteger)indexPath.row];
	NSArray *tapGestureRecognizersAttachedToCell = [cell.gestureRecognizers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		return [evaluatedObject isKindOfClass:[UITapGestureRecognizer class]];
	}]];
	if ([tapGestureRecognizersAttachedToCell count] == 0) {
		[cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appTapped:)]];
	}
	
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat spacingBetweenApps = ((UICollectionViewFlowLayout *)collectionViewLayout).minimumInteritemSpacing;
	if (_appsRowGapBetweenApps > spacingBetweenApps) spacingBetweenApps = _appsRowGapBetweenApps;
	
	return CGSizeMake(_appIconWidth + spacingBetweenApps / 2.0f, collectionView.height - collectionView.contentInset.top - collectionView.contentInset.bottom);
}

@end

// Other classes

@interface SBChoosyAppCell ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *labelTitle;
@property (nonatomic) UIView *containerView;

@end

@implementation SBChoosyAppCell

static CGFloat _paddingBetweenTextAndImage = 5;

- (id)init
{
	if (self = [super init]) {
		[self initialize];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self initialize];
	}
	return self;
}

- (void)initialize {
	self.containerView = [UIView new];
	self.containerView.backgroundColor = [UIColor clearColor];
	[self addSubview:self.containerView];
	self.backgroundColor = [UIColor clearColor];
}

- (void)setAppInfo:(SBChoosyPickerAppInfo *)appInfo
{
	if (!appInfo) return;
	
	_appInfo = appInfo;
	self.backgroundColor = [UIColor clearColor];
	self.imageView.image = _appInfo.appIcon;
	self.imageView.backgroundColor = [UIColor clearColor];
	self.labelTitle.text = _appInfo.appName;
	[self.labelTitle sizeToFit];
	self.labelTitle.backgroundColor = [UIColor clearColor];
	self.labelTitle.textColor = [UIColor whiteColor];
	
	CGFloat totalHeightOfItemsInCell = _appIconHeight + self.labelTitle.height + _paddingBetweenTextAndImage;
	
	// really the whole purpose of container view was so that I can center views easier hah
	self.containerView.bounds = CGRectMake(0, 0, self.width - 10, totalHeightOfItemsInCell);
	self.containerView.center = CGPointMake(self.width / 2.0f, self.height / 2.0f);
	
	// position image and title inside the container view
	self.imageView.bounds = CGRectMake(0, 0, _appIconWidth, _appIconHeight);
	self.imageView.center = CGPointMake(self.containerView.width / 2.0f, self.imageView.height / 2.0f);
	self.labelTitle.center = CGPointMake(self.containerView.width / 2.0f, self.imageView.height + _paddingBetweenTextAndImage + self.labelTitle.height / 2.0f);
}

- (UIImageView *)imageView
{
	if (!_imageView) {
		_imageView = [UIImageView new];
		[self.containerView addSubview:_imageView];
	}
	return _imageView;
}

- (UILabel *)labelTitle
{
	if (!_labelTitle) {
		_labelTitle = [UILabel new];
		_labelTitle.font = [UIFont systemFontOfSize:12];
		_labelTitle.textColor = [UIColor blackColor];
		[self.containerView addSubview:_labelTitle];
	}
	return _labelTitle;
}

@end
