
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"

/**
 *  Interface to remotely stored data.
 */
@interface SBChoosyNetworkStore : NSObject

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(SBChoosyAppType *appType))successBlock failure:(void(^)(NSError *error))failureBlock;
+ (void)downloadAppIconForAppKey:(NSString *)appKey success:(void(^)(UIImage *appIcon))successBlock failure:(void(^)(NSError *error))failureBlock;

@end
