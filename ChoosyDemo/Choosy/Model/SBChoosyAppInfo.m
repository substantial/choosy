
#import "SBChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppAction.h"

@interface SBChoosyAppInfo ()

//@property (nonatomic) NSNumber *isAppInstalled;

@end

@implementation SBChoosyAppInfo

static NSString *_appIconFileExtension = @"png";

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

+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey
{
    NSString *appIconName = [self appIconFileNameWithoutExtensionForAppKey:appKey];

    appIconName = [[appIconName stringByAppendingString:@"."] stringByAppendingString:[self appIconFileExtension]];

    return appIconName;
}

+ (NSString *)appIconFileNameWithoutExtensionForAppKey:(NSString *)appKey
{
    NSString *appIconName = appKey;
    // add suffix for retina screens
    NSInteger scale = (NSInteger)[[UIScreen mainScreen] scale];
    
    // ex: safari@2x.png
    if (scale > 1) appIconName = [appIconName stringByAppendingFormat:@"@%ldx", (long)scale];
    
    return appIconName;
}

+ (NSString *)appIconFileExtension
{
    return _appIconFileExtension;
}

@end
