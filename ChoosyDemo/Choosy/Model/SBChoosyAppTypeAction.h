
#import <Foundation/Foundation.h>

@class SBChoosyAppType;

@interface SBChoosyAppTypeAction : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) SBChoosyAppType *appType;
           
@end
