
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface ChoosyAppAction : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *actionKey;
@property (nonatomic, strong) NSString *urlFormat;

@end
