
#import "NSThread+Helpers.h"

@implementation NSThread (Helpers)

+ (void)executeOnMainThread:(void (^)())block
{
	if (!block) return;
	
	if ([[NSThread currentThread] isMainThread]) {
		block();
	} else {
		dispatch_sync(dispatch_get_main_queue(), ^ {
			block();
		});
	}
}

+ (void)executeOnNonMainThread:(void (^)())block withPriority:(long)priority
{
    if (!block) return;
    
    if ([[NSThread currentThread] isMainThread]) {
        dispatch_async(dispatch_get_global_queue(priority, 0), ^{
            block();
        });
    } else {
        block();
    }
}

@end
