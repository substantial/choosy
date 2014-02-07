
#import <Foundation/Foundation.h>

@interface SBChoosyPickerAppInfo : NSObject

// designated
- (instancetype)initWithName:(NSString *)appName key:(NSString *)appKey type:(NSString *)appType icon:(UIImage *)appIcon;

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSString *appType;
@property (nonatomic) UIImage *appIcon;

@end
