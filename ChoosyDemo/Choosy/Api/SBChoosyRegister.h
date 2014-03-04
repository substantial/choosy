/*
 * Create an instance of this on every view controller that has UI elements 
 * that you want to register with Choosy.
 */

#import <Foundation/Foundation.h>

@class SBChoosyActionContext, SBChoosyAppType, SBChoosyAppInfo;

@protocol SBChoosyRegisterDelegate <NSObject>

//- (void)didAddApp:(SBChoosyAppInfo *)newApp;
//
//- (void)didUpdateAppInfo:(SBChoosyAppInfo *)existingAppInfo
//          withNewAppInfo:(SBChoosyAppInfo *)updatedAppInfo;

- (void)didDownloadAppIcon:(UIImage *)appIcon forApp:(SBChoosyAppInfo *)app;

@end

@interface SBChoosyRegister : NSObject

+ (instancetype)sharedInstance;
@property (nonatomic, weak) id<SBChoosyRegisterDelegate> delegate;

- (void)registerAppTypes:(NSArray *)appTypes;
- (void)update;
- (void)takeStockOfAppsForAppType:(SBChoosyAppType *)appType;

- (void)addAppType:(SBChoosyAppType *)appTypeToAdd then:(void(^)())block;
- (void)appTypeWithKey:(NSString *)appTypeKey then:(void(^)(SBChoosyAppType *))block;
- (UIImage *)appIconForAppKey:(NSString *)appKey;

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey;
- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey;
- (void)resetDefaultAppForAppTypeKey:(NSString *)appTypeKey;

@end
