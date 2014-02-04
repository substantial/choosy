
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"
#import "SBChoosyAppInfo.h"

/**
 *  Interface to locally stored data.
 */
@interface SBChoosyLocalStore : NSObject

/**
 *  Returns list of app types found in local cache.
 *
 *  @return Array of SBChoosyCachedAppType objects.
 */
- (NSArray *)cachedAppTypes;

/**
 *  Returns list of apps found in local cache.
 *
 *  @param appType Type of the apps.
 *
 *  @return Array of SBChoosyAppInfo objects.
 */
- (NSArray *)cachedAppInfosForAppType:(NSString *)appType;

@end


@interface SBChoosyCachedAppType : SBChoosyAppType

// designated
- (instancetype)initWithAppType:(SBChoosyAppType *)appType dateCached:(NSDate *)dateCached;

@property (nonatomic, readonly) NSDate *dateCached;

@end


@interface SBChoosyCachedAppInfos : SBChoosyAppInfo

// designated
- (instancetype)initWithAppInfo:(SBChoosyAppInfo *)appInfo dateCached:(NSDate *)dateCached;

@property (nonatomic, readonly) NSDate *dateCached;

@end