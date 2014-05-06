
#import "ChoosyAppInfo.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "ChoosyAppAction.h"
#import "ChoosyNetworkStore.h"
#import "ChoosyLocalStore.h"
#import "NSThread+Helpers.h"
#import "UIImage+ImageEffects.h"

NSString * const ChoosyDidUpdateAppIconNotification = @"ChoosyDidUpdateAppIconNotification";

@implementation ChoosyAppInfo

- (ChoosyAppAction *)findActionWithKey:(NSString *)actionKey
{
    for (ChoosyAppAction *action in self.appActions) {
        if ([[action.actionKey lowercaseString] isEqualToString:[actionKey lowercaseString]]) {
            return action;
        }
    }
    
    return nil;
}

- (void)downloadAppIcon
{
    __weak ChoosyAppInfo *appInfo = self;
    [ChoosyNetworkStore downloadAppIconForAppKey:self.appKey success:^(UIImage *appIcon)
     {
         // mask the icon here so we don't do it every time the icon is displayed
         [appIcon applyMaskImage:[ChoosyLocalStore appIconMask] completion:^(UIImage *maskedIcon) {
             // the above 'maskedIcon' will show up masked if thrown into a UIImageView
             // but if you save it to file using UIImagePNGRepresentation, you won't see the mask
             // sooo what we want to do is we want to render to context first to merge mask onto image
             // (think of flattening layers in Photoshop)
             UIGraphicsBeginImageContext(maskedIcon.size);
             [maskedIcon drawAtPoint:CGPointZero];
             maskedIcon = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             [ChoosyLocalStore cacheAppIcon:maskedIcon forAppKey:appInfo.appKey];
             
             // tell everyone icon got updated! woooo
             [NSThread executeOnMainThread:^{
                 [[NSNotificationCenter defaultCenter] postNotificationName:ChoosyDidUpdateAppIconNotification object:appInfo userInfo:@{@"appIcon" : maskedIcon}];
             }];
         }];
     } failure:^(NSError *error) {
         NSLog(@"Couldn't download icon for app key %@", appInfo.appKey);
     }];
}

#pragma mark MTLJSONSerializing

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"appName" : @"name",
             @"appKey" : @"key",
             @"appURLScheme" : @"app_url_scheme",
             @"appActions" : @"actions",
             @"isInstalled" : NSNull.null,
             @"isNew" : NSNull.null,
             @"isDefault" : NSNull.null,
             @"isAppIconDownloading" : NSNull.null
             };
}

+ (NSValueTransformer *)appActionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ChoosyAppAction class]];
}

+ (NSValueTransformer *)appURLSchemeJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

@end
