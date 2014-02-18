
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

/**
 *  This defines abstract action for a specific app type. For example, Twitter app type would have AppTypeActions like Show Profile, Tweet, Show Timeline, Open DMs, etc.
 */
@interface SBChoosyAppTypeAction : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *key;
           
@end
