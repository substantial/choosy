

#import <UIKit/UIKit.h>

@protocol SBChoosyPickerDelegate <NSObject>

@required
- (void)didCancelAppSelection;
- (void)didSelectApp:(NSString *)appKey;

@end

@interface SBChoosyAppPickerViewController : UIViewController

@property (nonatomic, weak) id<SBChoosyPickerDelegate> delegate;

@end
