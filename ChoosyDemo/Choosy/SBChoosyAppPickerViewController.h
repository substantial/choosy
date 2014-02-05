

#import <UIKit/UIKit.h>
#import "SBChoosyAppInfo.h"

@protocol SBChoosyPickerDelegate <NSObject>

@required
- (void)didDismissAppPicker;
- (void)didSelectApp:(NSString *)appKey;

@end

@interface SBChoosyAppPickerViewController : UIViewController

// designated
- (instancetype)initWithApps:(NSArray *)apps;

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;
@property (nonatomic) NSString *pickerTitle;
@property (nonatomic) NSString *pickerText;

@end

@interface SBChoosyAppPickerAppInfo : SBChoosyAppInfo

@property (nonatomic, readonly) UIImage *appIcon;

@end

@interface SBChoosyAppCell : UICollectionViewCell

@property (nonatomic) SBChoosyAppPickerAppInfo *app;

@end
