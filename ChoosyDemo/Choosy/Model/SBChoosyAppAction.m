
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

+ (NSValueTransformer *)urlFormatJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
