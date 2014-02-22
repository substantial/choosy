
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

@end
