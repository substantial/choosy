
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"
#import "SBChoosyAppInfo.h"

/**
 *  Interface to locally stored data.
 */
@interface SBChoosyLocalStore : NSObject

+ (NSArray *)lastDetectedAppsForAppType:(NSString *)appType;
+ (void)setLastDetectedApps:(NSArray *)appKeys forAppType:(NSString *)appType;

+ (NSString *)defaultAppForAppType:(NSString *)appType;
+ (void)setDefaultApp:(NSString *)appKey forAppType:(NSString *)appType;

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

+ (SBChoosyAppType *)getBuiltInAppType:(NSString *)appTypeKey;

+ (void)cacheAppTypes:(NSArray *)jsonAppTypes;
@end