
#import "SBChoosyAppType.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyAppTypeAction.h"
#import "SBChoosyAppInfo.h"

@implementation SBChoosyAppType

+ (SBChoosyAppType *)filterAppTypesArray:(NSArray *)appTypes byKey:(NSString *)appTypeKey
{
    if (!appTypes || !appTypeKey) return nil;
    
    for (SBChoosyAppType *appType in appTypes) {
        if ([appType.key isEqualToString:appTypeKey]) {
            return appType;
        }
    }
    
    return nil;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    // no special mapping
    return @{};
}

+ (NSValueTransformer *)parametersJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppTypeParameter class]];
}

+ (NSValueTransformer *)actionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppTypeAction class]];
}

+ (NSValueTransformer *)appsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppInfo class]];
}

@end
