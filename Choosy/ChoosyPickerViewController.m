#import "ChoosyPickerViewController.h"
#import "UIView+Helpers.h"
#import "UIView+Screenshot.h"
#import "UIImage+ImageEffects.h"
#import "ChoosyPickerViewModel.h"
#import "NSThread+Helpers.h"
#import "SBReversibleAnimation.h"
#import "NSArray+ObjectiveSugar.h"
//#import "ChoosyPickerView.h"

@interface ChoosyAppCell : UICollectionViewCell

@property (nonatomic) ChoosyPickerAppInfo *appInfo;

@end

@interface ChoosyAppPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) ChoosyPickerViewModel *viewModel;

@property (nonatomic) UIView *contentArea; // this is the whole visible part
@property (nonatomic) UIView *appRow; // this is just the row showing app icons
@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) UIView *titleView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UIImageView *blurredBackground;
@property (nonatomic) UIView *blurVeilView;
@property (nonatomic) UIView *backgroundTint;
@property (nonatomic) UIView *instructionTextView;
@property (nonatomic) UILabel *instructionTextLabel;
@property (nonatomic) UILabel *confirmationTextLabel;
@property (nonatomic) UIButton *cancelButton;

//@property (nonatomic) NSMutableDictionary *animationsForSettingDefaultApp;
@property (nonatomic) NSMutableArray *animationsForSettingDefaultApp;

@end

@implementation ChoosyAppPickerViewController {
    BOOL _completedSettingDefault;
}

static CGFloat _appIconHeight = 60;
static CGFloat _appIconWidth = 60;
static CGFloat _appsRowLeftPadding = 5;
static CGFloat _appsRowGapBetweenApps = 10;

- (instancetype)initWithModel:(ChoosyPickerViewModel *)viewModel
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
    
    [self createViewElements];
    
	// add gesture recognizers for dismissing the view
    // tap (outside the content area)
	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)]];
    
    // swipe (down)
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(viewSwiped:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
	[self.view addGestureRecognizer:swipeDown];
}

- (void)createViewElements
{
	CGFloat appsCollectionViewHeight = _appIconHeight * 2.0f;
	CGFloat titleHeight = 35;
    
    // create the layer that gives an overall darker tint to whatever view is behind
    self.backgroundTint = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundTint.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3f];
    self.backgroundTint.alpha = 0;
    [self.view addSubview:self.backgroundTint];
		
    // title text
    UIColor *lightGrayColor = [UIColor colorWithWhite:0.467195 alpha:1.0];
	self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, titleHeight)];
	self.titleView.backgroundColor = [UIColor clearColor];
	self.titleLabel = [[UILabel alloc] initWithFrame:self.titleView.bounds];
	self.titleLabel.textAlignment = NSTextAlignmentCenter;
	self.titleLabel.font = [UIFont systemFontOfSize:15];
	self.titleLabel.text = self.viewModel.pickerTitleText;
	self.titleLabel.textColor = lightGrayColor; //[UIColor blackColor];
	[self.titleView addSubview:self.titleLabel];
	
	// line separator
	UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.titleView.bottomY, self.view.width, 1 / [[UIScreen mainScreen] scale])];
	lineSeparator.backgroundColor = lightGrayColor;//[UIColor colorWithRed:162/255.0f green:155/255.0f blue:155/255.0f alpha:1];
    
    // instruction & confirmation text
    if (self.viewModel.allowDefaultAppSelection) {
        self.instructionTextView = [[UIView alloc] initWithFrame:CGRectMake(0, lineSeparator.bottomY, self.view.width, 30)];
        self.instructionTextView.backgroundColor = [UIColor clearColor];
        
        self.instructionTextLabel = [[UILabel alloc] initWithFrame:self.instructionTextView.bounds];
        self.instructionTextLabel.text = NSLocalizedString(@"Long-press app to always use it", @"'Long-press app to always use it' instruction text");
        self.instructionTextLabel.textColor = [UIColor grayColor];
        self.instructionTextLabel.textAlignment = NSTextAlignmentCenter;
        self.instructionTextLabel.font = [UIFont systemFontOfSize:13];
        
        self.confirmationTextLabel = [[UILabel alloc] initWithFrame:self.instructionTextView.bounds];
        self.confirmationTextLabel.text = NSLocalizedString(@"Default set! Long-press to reset", @"'Default set! Long-press to reset' confirmation text");
        self.confirmationTextLabel.textColor = [UIColor darkGrayColor];
        self.confirmationTextLabel.textAlignment = NSTextAlignmentCenter;
        self.confirmationTextLabel.font = self.instructionTextLabel.font;
        self.confirmationTextLabel.alpha = 0;
        
        [self.instructionTextView addSubview:self.instructionTextLabel];
        [self.instructionTextView addSubview:self.confirmationTextLabel];
    }
	
    // apps collection view
	UICollectionViewFlowLayout *collectionViewLayout = [UICollectionViewFlowLayout new];
	collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, self.viewModel.allowDefaultAppSelection ? self.instructionTextView.bottomY : lineSeparator.bottomY, self.view.width, appsCollectionViewHeight) collectionViewLayout:collectionViewLayout];
	self.collectionView.dataSource = self;
	self.collectionView.delegate = self;
	self.collectionView.backgroundColor = [UIColor clearColor];
	self.collectionView.pagingEnabled = NO;
    self.collectionView.alwaysBounceHorizontal = YES;
	[self.collectionView registerClass:[ChoosyAppCell class] forCellWithReuseIdentifier:@"cell"];
	self.collectionView.contentInset = UIEdgeInsetsMake(0, _appsRowLeftPadding, 0, _appsRowLeftPadding);
    
    // cancel button
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(0, self.collectionView.bottomY, self.view.width, 45);
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel button text") forState:UIControlStateNormal];
    self.cancelButton.backgroundColor = [UIColor colorWithRed:237/255.0f green:237/255.0f blue:242/255.0f alpha:0.85f];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:23];
    [self.cancelButton addTarget:self action:@selector(handleCancel) forControlEvents:UIControlEventTouchUpInside];
    
    // the view is full screen, so put all the elements in a smaller content area and stick it at the bottom of the view
	self.contentArea = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, self.cancelButton.bottomY)]; // will size to fit/be positioned at the end
	self.contentArea.backgroundColor = [UIColor clearColor];
    
    // this will contain a blurred image of w/e is behind contentArea
    self.blurredBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, 0)];
    self.blurredBackground.backgroundColor = [UIColor clearColor];
    self.blurredBackground.contentMode = UIViewContentModeBottom;
    self.blurredBackground.clipsToBounds = YES;
    self.blurredBackground.alpha = 0.75f;
    //NSLog(@"blur frame start: %@", NSStringFromCGRect(self.blurredBackground.frame));
    
    // the nearly-opaque view over the blurred background that smoothes out the blurred image
    self.blurVeilView = [[UIView alloc] initWithFrame:self.contentArea.bounds];
    self.blurVeilView.backgroundColor = [UIColor colorWithRed:238/255.0f green:239/255.0f blue:240/255.0f alpha:1.0f];
    self.blurVeilView.alpha = 0.8f;
    
    [self.contentArea addSubview:self.blurVeilView];
	[self.contentArea addSubview:self.titleView];
    [self.contentArea addSubview:self.instructionTextView];
    [self.contentArea addSubview:lineSeparator];
    [self.contentArea addSubview:self.collectionView];
    [self.contentArea addSubview:self.cancelButton];
	   
    [self.view addSubview:self.blurredBackground];
	[self.view addSubview:self.contentArea];
}

- (void)animateAppearanceWithDuration:(NSTimeInterval)duration
{
    CGRect backgroundRectInParentView = [self.parentViewController.view convertRect:CGRectMake(self.contentArea.fx,
                                                                                               self.view.height - self.contentArea.height,
                                                                                               self.view.width, self.contentArea.height)
                                                                             toView:self.parentViewController.view];
    UIImage *viewScreenshot = [self.parentViewController.view screenshotOfRect:backgroundRectInParentView];
    //NSLog(@"Rect for blur: %@", NSStringFromCGRect(backgroundRectInParentView));
    
    [NSThread executeOnNonMainThread:^{
        UIImage *blurredBackground = [viewScreenshot applyBlurWithRadius:16 tintColor:nil saturationDeltaFactor:1.f maskImage:nil];
        
        [NSThread executeOnMainThread:^{
            self.blurredBackground.image = blurredBackground;
            
            [UIView animateWithDuration:0.13f animations:^{
                self.blurredBackground.alpha = 0.94f;
                //self.blurVeilView.alpha = 0.8f;
            }];
        }];
    } withPriority:DISPATCH_QUEUE_PRIORITY_DEFAULT];
    
    CGFloat contentAreaNewY = (self.view.height - self.contentArea.height);
    CGFloat contentHeight = self.contentArea.height;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.contentArea setFy:contentAreaNewY];
        
        CGRect newFrame = self.blurredBackground.frame;
        newFrame.size.height = contentHeight;
        newFrame.origin.y = contentAreaNewY;
        self.blurredBackground.frame = newFrame;
        
        //NSLog(@"blur frame end: %@", NSStringFromCGRect(self.blurredBackground.frame));
        self.backgroundTint.alpha = 1.0f;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)animateDisappearanceWithDuration:(NSTimeInterval)duration completion:(void (^)())block
{
    [UIView animateWithDuration:duration animations:^{
        self.backgroundTint.alpha = 0;
        [self.contentArea setFy:self.view.height];
        //[self.blurredBackground setFy:self.view.height];
        CGRect newFrame = self.blurredBackground.frame;
        newFrame.size.height = 0;
        newFrame.origin.y = self.view.height;
        self.blurredBackground.frame = newFrame;
        self.blurredBackground.alpha = 0.75f;
    } completion:^(BOOL finished) {
        if (block) {
            block();
        }
    }];
}

- (void)selectAppAsDefault:(NSString *)appKey
{
    [self.delegate didSelectAppAsDefault:appKey];
    _completedSettingDefault = NO;
}

- (void)updateIconForAppKey:(NSString *)appKey withIcon:(UIImage *)appIcon
{
    for (ChoosyPickerAppInfo *app in self.viewModel.appTypeInfo.installedApps) {
        if ([app.appKey isEqualToString:appKey]) {
            app.appIcon = appIcon;
            
            // TODO: make this better!
            [self.collectionView reloadData];
        }
    }
}

#pragma mark Properties

- (void)setPickerTitle:(NSString *)pickerTitle
{
    self.titleLabel.text = pickerTitle;
}

- (void)setTitleToDisplay:(NSString *)titleToDisplay
{
	self.titleLabel.text = titleToDisplay;
}

- (CGRect)visibleRect
{
	return self.contentArea.frame;
}

#pragma mark Gestures

- (void)viewTapped:(UITapGestureRecognizer *)gesture
{
	CGPoint point = [gesture locationInView:self.view];
	
	if (!CGRectContainsPoint(self.contentArea.frame, point)) {
		// tapped outside of sharing sheet - interpret as dismiss
		[self.delegate didRequestPickerDismissal];
	}
}

- (void)viewSwiped:(UISwipeGestureRecognizer *)gesture
{
	if ((gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateRecognized) && gesture.direction == UISwipeGestureRecognizerDirectionDown) {
		// interpret swipe down as dismiss
		[self.delegate didRequestPickerDismissal];
	}
}

- (void)appTapped:(UITapGestureRecognizer *)gesture
{
	ChoosyAppCell *cell = (ChoosyAppCell *)gesture.view;
	
	NSString *appKey = cell.appInfo.appKey;
    
	[self.delegate didSelectApp:appKey];
}

- (void)appLongPressed:(UILongPressGestureRecognizer *)gesture
{
    ChoosyAppCell *cell = (ChoosyAppCell *)gesture.view;
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            if (!_completedSettingDefault) {
                [self startSettingDefaultAppAnimation:cell];
            }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            if (!_completedSettingDefault) {
                [self stopSettingDefaultAppAnimation:cell];
            }
            break;
            
        default:
            break;
    }
}

- (void)startSettingDefaultAppAnimation:(ChoosyAppCell *)cell
{
    CFTimeInterval fadeOutDuration = 0.55f;
    
    // fade out the instruction text
    SBReversibleAnimation *instructionTextAnimation = [SBReversibleAnimation animationWithKeyPath:@"opacity"];
    instructionTextAnimation.duration = fadeOutDuration;
    instructionTextAnimation.startValue = @(1.f);
    instructionTextAnimation.endValue = @(0);
    instructionTextAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    instructionTextAnimation.layer = self.instructionTextLabel.layer;
    instructionTextAnimation.animationCompletionBlock = ^void() {
        _completedSettingDefault = YES;
        self.confirmationTextLabel.alpha = 1.f;
        self.cancelButton.enabled = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self selectAppAsDefault:cell.appInfo.appKey];
        });
    };
    [self.animationsForSettingDefaultApp addObject:instructionTextAnimation];
    
    // fade out other app icons
    for (ChoosyAppCell *otherCell in [self.collectionView visibleCells]) {
        if (otherCell == cell) continue;
        
        SBReversibleAnimation *fadeAppOutAnimation = [SBReversibleAnimation animationWithKeyPath:@"opacity"];
        fadeAppOutAnimation.duration = fadeOutDuration;
        fadeAppOutAnimation.startValue = @(1.f);
        fadeAppOutAnimation.endValue = @(0.2f);
        fadeAppOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        fadeAppOutAnimation.layer = otherCell.layer;
        [self.animationsForSettingDefaultApp addObject:fadeAppOutAnimation];
    }
    
    [self.animationsForSettingDefaultApp each:^(id object) {
        [((SBReversibleAnimation *)object) start];
    }];
 }

- (void)stopSettingDefaultAppAnimation:(ChoosyAppCell *)cell
{
    [self.animationsForSettingDefaultApp each:^(id object) {
        [((SBReversibleAnimation *)object) reverse];
    }];
    
    [self.animationsForSettingDefaultApp removeAllObjects];
}

- (NSMutableArray *)animationsForSettingDefaultApp
{
    if (!_animationsForSettingDefaultApp) {
        _animationsForSettingDefaultApp = [NSMutableArray new];
    }
    return _animationsForSettingDefaultApp;
}

- (void)handleCancel
{
    [self.delegate didRequestPickerDismissal];
}

#pragma mark Collection View delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return (NSInteger)[self.viewModel.appTypeInfo.installedApps count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ChoosyAppCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
	
	cell.appInfo = self.viewModel.appTypeInfo.installedApps[(NSUInteger)indexPath.row];
	NSArray *tapGestureRecognizersAttachedToCell = [cell.gestureRecognizers select:^BOOL(id object) {
        return [object isKindOfClass:[UITapGestureRecognizer class]];
    }];
	if ([tapGestureRecognizersAttachedToCell count] == 0) {
		[cell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appTapped:)]];
	}
    
    if (self.viewModel.allowDefaultAppSelection) {
        NSArray *longPressGestureRecognizersAttachedToCell = [cell.gestureRecognizers select:^BOOL(id object) {
            return [object isKindOfClass:[UILongPressGestureRecognizer class]];
        }];
        if ([longPressGestureRecognizersAttachedToCell count] == 0) {
            [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(appLongPressed:)]];
        }
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


@interface ChoosyAppCell ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *labelTitle;
@property (nonatomic) UIView *containerView;

@end

@implementation ChoosyAppCell

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

- (void)setAppInfo:(ChoosyPickerAppInfo *)appInfo
{
	if (!appInfo) return;
	
	_appInfo = appInfo;
	self.imageView.image = _appInfo.appIcon;
	self.imageView.backgroundColor = [UIColor clearColor];
	self.labelTitle.text = _appInfo.appName;
	[self.labelTitle sizeToFit];
	self.labelTitle.backgroundColor = [UIColor clearColor];
	self.labelTitle.textColor = [UIColor blackColor];
	
	CGFloat totalHeightOfItemsInCell = _appIconHeight + self.labelTitle.height + _paddingBetweenTextAndImage;
	
	// really the whole purpose of container view was so that I can center views easier hah
	self.containerView.bounds = CGRectMake(0, 0, self.width, totalHeightOfItemsInCell);
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
