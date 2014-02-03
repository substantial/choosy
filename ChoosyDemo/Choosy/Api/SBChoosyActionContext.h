
#import <Foundation/Foundation.h>

/*
 Used to define a specific action in Choosy
 */
@interface SBChoosyActionContext : NSObject

@property (nonatomic) NSString *appType;
@property (nonatomic) NSString *action;
@property (nonatomic) NSArray *parameters;

@end
