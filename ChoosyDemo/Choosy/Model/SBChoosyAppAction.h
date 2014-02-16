
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppTypeAction;

@interface SBChoosyAppAction : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *actionKey;
@property (nonatomic) NSString *urlFormat;

@end
