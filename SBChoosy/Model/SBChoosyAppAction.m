
#import "SBChoosyAppAction.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"

@implementation SBChoosyAppAction

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"actionKey" : @"key",
             @"urlFormat" : @"url_format"
             };
}

@end
