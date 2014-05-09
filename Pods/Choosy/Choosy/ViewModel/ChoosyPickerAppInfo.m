
#import "ChoosyPickerAppInfo.h"

@implementation ChoosyPickerAppInfo

- (instancetype)initWithName:(NSString *)appName key:(NSString *)appKey icon:(UIImage *)appIcon
{
    if (self = [super init]) {
        _appName = appName;
        _appKey = appKey;
        _appIcon = appIcon;
    }
    return self;
}

@end
