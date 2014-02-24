
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppAction;

@interface SBChoosyAppInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSURL *appURLScheme;
@property (nonatomic) NSArray *appActions; // of SBChoosyAppAction

@property (nonatomic) BOOL isInstalled;
@property (nonatomic) BOOL isNew;
@property (nonatomic) BOOL isDefault;

@property (nonatomic) BOOL isAppIconDownloading;

- (SBChoosyAppAction *)findActionWithKey:(NSString *)actionKey;

- (void)downloadAppIcon:(void (^)(UIImage *))successBlock;

+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey;
+ (NSString *)appIconFileNameWithoutExtensionForAppKey:(NSString *)appKey;
+ (NSString *)appIconFileExtension;

@end
