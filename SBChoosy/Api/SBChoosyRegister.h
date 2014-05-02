/*
 * Create an instance of this on every view controller that has UI elements 
 * that you want to register with Choosy.
 */

#import <Foundation/Foundation.h>

@class SBChoosyActionContext, SBChoosyAppType, SBChoosyAppInfo;

@interface SBChoosyRegister : NSObject

+ (instancetype)sharedInstance;

- (void)registerAppTypes:(NSArray *)appTypes;
- (void)registerAppTypeWithKey:(NSString *)appTypeKey;
- (void)updateRegisteredAppTypes;

- (void)findAppTypeWithKey:(NSString *)appTypeKey andIfFound:(void(^)(SBChoosyAppType *appType))successBlock ifNotFound:(void(^)())failureBlock;
- (UIImage *)appIconForAppKey:(NSString *)appKey;

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey;
- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey;
- (void)resetDefaultAppForAppTypeKey:(NSString *)appTypeKey;

@end
