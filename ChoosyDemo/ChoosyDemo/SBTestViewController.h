
#import <UIKit/UIKit.h>
#import "SBChoosy.h"

@interface SBTestViewController : UIViewController <SBChoosyDelegate>

@property (nonatomic, weak) id<SBChoosyDelegate> delegate;

@end
