
#import <Foundation/Foundation.h>
#import "ChoosyAppType.h"

/**
 *  Interface to remotely stored data.
 */
@interface ChoosyNetworkStore : NSObject

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(ChoosyAppType *appType))successBlock failure:(void(^)(NSError *error))failureBlock;
+ (void)downloadAppIconForAppKey:(NSString *)appKey success:(void(^)(UIImage *appIcon))successBlock failure:(void(^)(NSError *error))failureBlock;

@end
