
#import <Foundation/Foundation.h>

@class SBChoosyAppType;

@interface SBChoosyApp : NSObject

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *uniqueName;
@property (nonatomic, readonly) SBChoosyAppType *type;
@property (nonatomic, readonly) NSArray *supportedActions; // of SBChoosyAppAction

@end
