
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface ChoosyAppTypeParameter : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *parameterDescription;
@property (nonatomic, strong) NSString *key;
@property (nonatomic) BOOL isPresenceRequired;
@property (nonatomic) BOOL isValueRequired;

@end
