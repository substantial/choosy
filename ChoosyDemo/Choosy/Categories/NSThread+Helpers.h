
#import <Foundation/Foundation.h>

@interface NSThread (Helpers)

+ (void)executeOnMainThread:(void(^)())block;
+ (void)executeOnNonMainThread:(void (^)())block withPriority:(long)priority;

@end
