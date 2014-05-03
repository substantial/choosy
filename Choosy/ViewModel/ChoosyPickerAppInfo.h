
#import <Foundation/Foundation.h>

@interface ChoosyPickerAppInfo : NSObject

// designated
- (instancetype)initWithName:(NSString *)appName key:(NSString *)appKey icon:(UIImage *)appIcon;

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) UIImage *appIcon;

/**
 *  YES if this is a new app since the last time a default app was selected by user.
 */
@property (nonatomic) BOOL *isNew;

@end
