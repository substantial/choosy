
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"
#import "SBChoosyAppInfo.h"

/**
 *  Interface to locally stored data.
 */
@interface SBChoosyLocalStore : NSObject

+ (NSArray *)lastDetectedAppKeysForAppTypeWithKey:(NSString *)appType;
+ (void)setLastDetectedAppKeys:(NSArray *)appKeys forAppTypeKey:(NSString *)appType;

+ (NSString *)defaultAppForAppTypeKey:(NSString *)appType;
+ (void)setDefaultApp:(NSString *)appKey forAppTypeKey:(NSString *)appType;

// READ
/**
 *  Returns list of app types found in local cache.
 *
 *  @return Array of SBChoosyCachedAppType objects.
 */
+ (NSArray *)cachedAppTypes;

/**
 *  Returns list of apps found in local cache.
 *
 *  @param appType Type of the apps.
 *
 *  @return Array of SBChoosyAppInfo objects.
 */
+ (SBChoosyAppType *)cachedAppType:(NSString *)appTypeKey;

+ (SBChoosyAppType *)builtInAppType:(NSString *)appTypeKey;

+ (void)cacheAppTypes:(NSArray *)jsonAppTypes;

+ (BOOL)appIconExistsForAppKey:(NSString *)appKey;
+ (UIImage *)appIconForAppKey:(NSString *)appKey;
+ (void)cacheAppIcon:(UIImage *)appIcon forAppKey:(NSString *)appKey;

@end