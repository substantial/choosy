
#import "SBChoosyPickerAppInfo.h"

@implementation SBChoosyPickerAppInfo

- (instancetype)initWithName:(NSString *)appName key:(NSString *)appKey type:(NSString *)appType icon:(UIImage *)appIcon
{
    if (self = [super init]) {
        _appName = appName;
        _appKey = appKey;
        _appType = appType;
        _appIcon = appIcon;
    }
    return self;
}

@end
