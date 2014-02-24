
#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@class SBChoosyAppInfo;

@protocol SBChoosyAppTypeDelegate <NSObject>

- (void)didDownloadAppIcon:(UIImage *)appIcon forApp:(SBChoosyAppInfo *)app;

@end

@interface SBChoosyAppType : MTLModel <MTLJSONSerializing>

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *key;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSArray *actions;
@property (nonatomic) NSArray *apps;

// Date the app type was last udpated from the server. If more than X hours old,
// the object is considered invalid and only used if data cannot be retrieved from server
@property (nonatomic) NSDate *dateUpdated;

@property (nonatomic, weak) id<SBChoosyAppTypeDelegate> delegate;

/**
 *  Check which apps that belong to this app type, if any, are installed on the device.
 *
 *  @return Array of SBChoosyAppInfo objects representing installed apps, or nil if none are installed.
 */
- (NSArray *)installedApps;
- (SBChoosyAppInfo *)defaultApp;

+ (SBChoosyAppType *)filterAppTypesArray:(NSArray *)appTypes byKey:(NSString *)appTypeKey;
- (SBChoosyAppInfo *)findAppInfoWithAppKey:(NSString *)appKey;

-(void)takeStockOfApps;

@end
