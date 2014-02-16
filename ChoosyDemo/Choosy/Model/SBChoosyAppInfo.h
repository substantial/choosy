
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppType;

@interface SBChoosyAppInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSArray *appActions; // of SBChoosyAppAction

//- (instancetype)initWithName:(NSString *)name key:(NSString *)key type:(NSString *)type actions:(NSArray *)actions;

@end
