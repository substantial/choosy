
#import "SBChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "SBChoosyAppAction.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyLocalStore.h"

@implementation SBChoosyAppInfo

static NSString *_appIconFileExtension = @"png";

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey
{
    for (SBChoosyAppAction *action in self.appActions) {
        if ([[action.actionKey lowercaseString] isEqualToString:[actionKey lowercaseString]]) {
            return action;
        }
    }
    
    return nil;
}

- (void)downloadAppIcon:(void (^)(UIImage *))successBlock
{
    if (self.isAppIconDownloading == YES) return;
    
    self.isAppIconDownloading = YES;
    [SBChoosyNetworkStore downloadAppIconForAppKey:self.appKey success:^(UIImage *appIcon)
     {
         // TODO: make sure this doesn't execute multiple times for same app key... ugh bug somewhere
         [SBChoosyLocalStore cacheAppIcon:appIcon forAppKey:self.appKey];
         self.isAppIconDownloading = NO;
         
         if (successBlock) {
             successBlock(appIcon);
         }
     } failure:^(NSError *error) {
         NSLog(@"Couldn't download icon for app key %@", self.appKey);
         self.isAppIconDownloading = NO;
     }];
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
