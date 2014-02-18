
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppAction;

@interface SBChoosyAppInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSURL *appURLScheme;
@property (nonatomic) NSArray *appActions; // of SBChoosyAppAction

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey;

@end
