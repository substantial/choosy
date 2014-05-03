
#import <Foundation/Foundation.h>

@class ChoosyActionContext;

@protocol ChoosyPickerDelegate <NSObject>

@required
- (void)didDismissPicker;
- (void)didSelectApp:(NSString *)appKey;
- (void)didSelectAppAsDefault:(NSString *)appKey;

@end

