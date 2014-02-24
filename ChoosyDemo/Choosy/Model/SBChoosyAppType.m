
#import "SBChoosyAppType.h"
#import "SBChoosyAppTypeParameter.h"
#import "SBChoosyAppTypeAction.h"
#import "SBChoosyAppInfo.h"
#import "MTLValueTransformer.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "NSArray+ObjectiveSugar.h"
#import "SBChoosyLocalStore.h"
#import "SBChoosyNetworkStore.h"
#import "SBChoosyAppType+Protected.h"
#import "NSDate-Utilities.h"

@implementation SBChoosyAppType

- (NSArray *)installedApps
{
    return [self.apps select:^BOOL(id object) {
        return ((SBChoosyAppInfo *)object).isInstalled;
    }];
}

- (SBChoosyAppInfo *)defaultApp
{
    NSString *defaultAppKey = [SBChoosyLocalStore defaultAppForAppTypeKey:self.key];
    if (!defaultAppKey) return nil;
    
    return [self.apps detect:^BOOL(id object) {
        return [((SBChoosyAppInfo *)object).appKey isEqualToString:defaultAppKey];
    }];
}

+ (SBChoosyAppType *)filterAppTypesArray:(NSArray *)appTypes byKey:(NSString *)appTypeKey
{
    if (!appTypes || !appTypeKey) return nil;
    
    @synchronized(appTypes) {
        for (SBChoosyAppType *appType in appTypes) {
            if ([appType.key isEqualToString:appTypeKey]) {
                return appType;
            }
        }
    }
    
    return nil;
}

- (SBChoosyAppInfo *)findAppInfoWithAppKey:(NSString *)appKey
{
    if (!self.apps) return nil;
    
    for (SBChoosyAppInfo *appInfo in self.apps) {
        if ([appInfo.appKey isEqualToString:appKey]) {
            return appInfo;
        }
    }
    
    return nil;
}

- (void)takeStockOfApps
{
    [self checkForInstalledApps];
    
    [self checkForNewlyInstalledAppsGivenLastDetectedAppKeys:[SBChoosyLocalStore lastDetectedAppKeysForAppTypeWithKey:self.key]];
    
    // check if icons need to be downloaded
    [self downloadAppIcons];
}

- (void)downloadAppIcons
{
    for (SBChoosyAppInfo *app in [self installedApps]) {
        [self downloadAppIconForApp:app];
    }
}

- (void)downloadAppIconForApp:(SBChoosyAppInfo *)app
{
    // TODO: make this a serial queue? b/c weird stuff's going on otherwise, it seems
    
    if (![SBChoosyLocalStore appIconExistsForAppKey:app.appKey] && !app.isAppIconDownloading)
    {
        [app downloadAppIcon:^(UIImage *appIcon)
        {
            // notify the delegate, if it subscribed to the event
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(didDownloadAppIcon:forApp:)]) {
                    [self.delegate didDownloadAppIcon:appIcon forApp:app];
                }
            });
        }];
    }
}

#pragma mark Mantle

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    // no special mapping
    return @{
             @"delegate" : NSNull.null
             };
}

+ (NSValueTransformer *)dateUpdatedJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        NSDate *date = [self.dateFormatter dateFromString:str];
        return date;
    } reverseBlock:^(NSDate *date) {
        return [self.dateFormatter stringFromDate:date];
    }];
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

+ (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_formatter;
    
    if (!_formatter) {
        _formatter = [NSDateFormatter new];
        _formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return _formatter;
}

@end
