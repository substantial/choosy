
#import "ChoosyAppTypeParameter.h"

@implementation ChoosyAppTypeParameter

- (void)setKey:(NSString *)key
{
    _key = [key lowercaseString];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{ @"isPresenceRequired" : @"presence_required",
              @"isValueRequired" : @"value_required",
              @"parameterDescription" : @"description"};
}

@end
