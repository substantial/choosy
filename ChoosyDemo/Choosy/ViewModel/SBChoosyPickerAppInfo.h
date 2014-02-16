
#import <Foundation/Foundation.h>

@interface SBChoosyPickerAppInfo : NSObject

// designated
- (instancetype)initWithName:(NSString *)appName key:(NSString *)appKey icon:(UIImage *)appIcon;

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) UIImage *appIcon;

@end
