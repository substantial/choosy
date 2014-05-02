
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppAction;

extern NSString * const SBChoosyDidUpdateAppIconNotification;

@protocol SBChoosyAppInfoDelegate <NSObject>

- (void)didUpdateAppIcon:(UIImage *)newAppIcon;

@end

@interface SBChoosyAppInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSURL *appURLScheme;
@property (nonatomic) NSArray *appActions; // of SBChoosyAppAction

@property (nonatomic) BOOL isInstalled;
@property (nonatomic) BOOL isNew;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isAppIconDownloading;
@property (nonatomic, weak) id delegate;

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey;

- (void)downloadAppIcon;

+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey;
+ (NSString *)appIconFileNameWithoutExtensionForAppKey:(NSString *)appKey;
+ (NSString *)appIconFileExtension;

@end
