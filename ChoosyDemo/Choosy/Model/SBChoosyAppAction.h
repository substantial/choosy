
#import <Foundation/Foundation.h>

@class SBChoosyAppTypeAction;

@interface SBChoosyAppAction : NSObject

@property (nonatomic, readonly) SBChoosyAppTypeAction *appTypeAction;
@property (nonatomic, readonly) NSString *urlFormat;

- (instancetype) initWithAppTypeAction:(SBChoosyAppTypeAction *)appTypeAction urlFormat:(NSArray *)urlFormat;

@end
