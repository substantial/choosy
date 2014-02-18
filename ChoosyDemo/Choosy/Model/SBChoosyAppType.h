
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppInfo;

@interface SBChoosyAppType : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *key;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSArray *actions;
@property (nonatomic) NSArray *apps;

// Date the app type was last udpated from the server. If more than X hours old,
// the object is considered invalid and only used if data cannot be retrieved from server
@property (nonatomic) NSDate *dateUpdated;

+ (SBChoosyAppType *)filterAppTypesArray:(NSArray *)appTypes byKey:(NSString *)appTypeKey;
- (SBChoosyAppInfo *)findAppInfoWithAppKey:(NSString *)appKey;

@end
