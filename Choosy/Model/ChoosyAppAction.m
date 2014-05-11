
#import "ChoosyAppAction.h"

@implementation ChoosyAppAction

- (void)setActionKey:(NSString *)actionKey
{
    _actionKey = [actionKey lowercaseString];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"actionKey" : @"key",
             @"urlFormat" : @"url_format"
             };
}

@end
