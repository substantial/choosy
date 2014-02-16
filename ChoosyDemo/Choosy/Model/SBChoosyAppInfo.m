
#import "SBChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppAction.h"

@implementation SBChoosyAppInfo

//- (instancetype)initWithName:(NSString *)name key:(NSString *)key type:(NSString *)type actions:(NSArray *)actions
//{
//    if (self = [super init]) {
//        _appName = name;
//        _appKey = key;
//        _appType = type;
//        _appActions = actions;
//    }
//    return self;
//}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"appName" : @"name",
             @"appKey" : @"key",
             @"appActions" : @"actions"
             };
}

+ (NSValueTransformer *)appActionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppAction class]];
}

@end
