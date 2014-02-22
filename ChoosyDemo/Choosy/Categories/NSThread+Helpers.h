
#import <Foundation/Foundation.h>

@interface NSThread (Helpers)

+ (void)executeOnMainThread:(void(^)())block;

@end
