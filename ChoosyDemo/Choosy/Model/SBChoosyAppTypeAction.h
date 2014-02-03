
#import <Foundation/Foundation.h>

@class SBChoosyAppType;

@interface SBChoosyAppTypeAction : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) SBChoosyAppType *appType;

// if an app wants to perform an action but we don't have connection to pull the list of apps,
// and no default was selected yet, this is the URL to use instead. Ex: if a mail link, this would be mail://
@property (nonatomic, readonly) NSString *defaultUrl;
           
@end
