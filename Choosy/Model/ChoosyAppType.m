
#import "ChoosyAppType.h"
#import "ChoosyAppTypeParameter.h"
#import "ChoosyAppTypeAction.h"
#import "ChoosyAppInfo.h"
#import "MTLValueTransformer.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "ChoosyLocalStore.h"
#import "ChoosyNetworkStore.h"
#import "ChoosyAppType+Protected.h"
#import "NSDate-Utilities.h"

@implementation ChoosyAppType

- (void)update
{
    [self takeStockOfApps];
}

- (NSArray *)installedApps
{
    NSMutableArray *installedApps = [NSMutableArray new];
    for (ChoosyAppInfo *appInfo in self.apps) {
        if (appInfo.isInstalled) [installedApps addObject:appInfo];
    }
    
    return [installedApps copy];
}

- (NSArray *)newApps
{
    NSMutableArray *newApps = [NSMutableArray new];
    for (ChoosyAppInfo *appInfo in self.apps) {
        if (appInfo.isNew) [newApps addObject:appInfo];
    }
    
    return [newApps copy];
}

- (ChoosyAppInfo *)defaultApp
{
    NSString *defaultAppKey = [ChoosyLocalStore defaultAppForAppTypeKey:self.key];
    if (!defaultAppKey) return nil;
    
    ChoosyAppInfo *defaultApp;
    for (ChoosyAppInfo *appInfo in self.apps) {
        if ([appInfo.appKey isEqualToString:defaultAppKey]) {
            defaultApp = appInfo;
            break;
        }
    }
    
    return defaultApp;
}

+ (ChoosyAppType *)filterAppTypesArray:(NSArray *)appTypes byKey:(NSString *)appTypeKey
{
    if (!appTypes || !appTypeKey) return nil;
    
    appTypeKey = [appTypeKey lowercaseString];
    @synchronized(appTypes) {
        for (ChoosyAppType *appType in appTypes) {
            if ([appType.key isEqualToString:appTypeKey]) {
                return appType;
            }
        }
    }
    
    return nil;
}

- (ChoosyAppInfo *)findAppInfoWithAppKey:(NSString *)appKey
{
    NSString *lowercaseKey = [appKey lowercaseString];
    for (ChoosyAppInfo *appInfo in self.apps) {
        if ([appInfo.appKey isEqualToString:lowercaseKey]) {
            return appInfo;
        }
    }
    return nil;
}

#pragma Properties

- (void)setKey:(NSString *)key
{
    _key = [key lowercaseString];
}

#pragma mark Mantle

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    // no special name mapping
    return @{};
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
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ChoosyAppTypeParameter class]];
}

+ (NSValueTransformer *)actionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ChoosyAppTypeAction class]];
}

+ (NSValueTransformer *)appsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[ChoosyAppInfo class]];
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
