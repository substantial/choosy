
#import <Foundation/Foundation.h>
#import "ChoosyAppType.h"
#import "ChoosyAppInfo.h"

/**
 *  Interface to locally stored data.
 */
@interface ChoosyLocalStore : NSObject

+ (NSArray *)lastDetectedAppKeysForAppTypeWithKey:(NSString *)appType;
+ (void)setLastDetectedAppKeys:(NSArray *)appKeys forAppTypeKey:(NSString *)appType;

+ (NSString *)defaultAppForAppTypeKey:(NSString *)appType;
+ (void)setDefaultApp:(NSString *)appKey forAppTypeKey:(NSString *)appType;

// READ
/**
 *  Returns list of app types found in local cache.
 *
 *  @return Array of ChoosyCachedAppType objects.
 */
+ (NSArray *)cachedAppTypes;

/**
 *  Returns list of apps found in local cache.
 *
 *  @param appType Type of the apps.
 *
 *  @return Array of ChoosyAppInfo objects.
 */
+ (ChoosyAppType *)cachedAppType:(NSString *)appTypeKey;

+ (ChoosyAppType *)builtInAppType:(NSString *)appTypeKey;

+ (void)cacheAppTypes:(NSArray *)jsonAppTypes;
+ (void)cacheAppType:(ChoosyAppType *)appType;

+ (void)cacheAppIcon:(UIImage *)appIcon forAppKey:(NSString *)appKey;

+ (BOOL)appIconExistsForAppKey:(NSString *)appKey;
+ (UIImage *)appIconForAppKey:(NSString *)appKey;
+ (UIImage *)appIconMask;
+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey;

@end
