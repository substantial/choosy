
#import "SBChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppAction.h"

@implementation SBChoosyAppInfo

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey
{
    for (SBChoosyAppAction *action in self.appActions) {
        if ([action.actionKey isEqualToString:actionKey]) {
            return action;
        }
    }
    
    return nil;
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"appName" : @"name",
             @"appKey" : @"key",
             @"appURLScheme" : @"app_url_scheme",
             @"appActions" : @"actions"
             };
}

+ (NSValueTransformer *)appActionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[SBChoosyAppAction class]];
}

+ (NSValueTransformer *)appURLSchemeJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
