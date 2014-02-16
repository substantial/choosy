
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"
#import "AFHTTPRequestOperationManager.h"

/**
 *  Interface to remotely stored data.
 */
@interface SBChoosyNetworkStore : NSObject

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(AFHTTPRequestOperation *operation, SBChoosyAppType *appType))successBlock;

@end
