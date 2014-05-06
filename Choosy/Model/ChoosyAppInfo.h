
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class ChoosyAppAction;

extern NSString * const ChoosyDidUpdateAppIconNotification;

@protocol ChoosyAppInfoDelegate <NSObject>

- (void)didUpdateAppIcon:(UIImage *)newAppIcon;

@end

@interface ChoosyAppInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *appName;
@property (nonatomic) NSString *appKey;
@property (nonatomic) NSURL *appURLScheme;
@property (nonatomic) NSArray *appActions; // of ChoosyAppAction

@property (nonatomic) BOOL isInstalled;
@property (nonatomic) BOOL isNew;
@property (nonatomic) BOOL isDefault;
@property (nonatomic) BOOL isAppIconDownloading;
@property (nonatomic, weak) id delegate;

- (ChoosyAppAction *)findActionWithKey:(NSString *)actionKey;

- (void)downloadAppIcon;

@end
