/*
 * Create an instance of this on every view controller that has UI elements 
 * that you want to register with Choosy.
 */

#import <Foundation/Foundation.h>

@class SBChoosyActionContext, SBChoosyAppType, SBChoosyAppInfo;

@interface SBChoosyRegister : NSObject

+ (instancetype)sharedInstance;

- (void)registerAppTypes:(NSArray *)appTypes;
- (void)update;

- (void)addAppType:(SBChoosyAppType *)appTypeToAdd then:(void(^)())block;
- (void)appTypeWithKey:(NSString *)appTypeKey then:(void(^)(SBChoosyAppType *))block;
- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock;

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey;
- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey;
- (void)resetDefaultAppForAppTypeKey:(NSString *)appTypeKey;

@end
