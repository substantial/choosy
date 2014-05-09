
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface ChoosyAppAction : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *actionKey;
@property (nonatomic) NSString *urlFormat;

@end
