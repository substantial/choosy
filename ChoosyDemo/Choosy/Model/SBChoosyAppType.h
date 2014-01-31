
#import <Foundation/Foundation.h>

@interface SBChoosyAppType : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *parameters;
@property (nonatomic, readonly) NSArray *actions;

- (instancetype)initWithName:(NSString *)name parameters:(NSArray *)parameters actions:(NSArray *)actions;

@end
