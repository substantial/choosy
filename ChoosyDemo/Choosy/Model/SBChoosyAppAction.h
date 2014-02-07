
#import <Foundation/Foundation.h>

@class SBChoosyAppTypeAction;

@interface SBChoosyAppAction : NSObject

@property (nonatomic, readonly) SBChoosyAppTypeAction *appTypeAction;
@property (nonatomic, readonly) NSString *urlFormat;

// note: we don't need a list of parameters here b/c it is derived from contents of urlFormat property

- (instancetype) initWithAppTypeAction:(SBChoosyAppTypeAction *)appTypeAction urlFormat:(NSArray *)urlFormat;

@end
