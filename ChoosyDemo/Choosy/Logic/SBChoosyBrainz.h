// This object manages app lists and app icons (downloads, cache)

#import <Foundation/Foundation.h>
#import "SBChoosyActionContext.h"
#import "SBChoosyAppType.h"

@class SBChoosyAppInfo;

#define SBCHOOSY_DEVELOPMENT_MODE 1
#define SBCHOOSY_UPDATE_INTERVAL 24 * 3600

// TODO: this is really an AppTypeStore, rename for clarity?

@protocol SBChoosyBrainzDelegate <NSObject>

@required
- (void)didAddAppType:(SBChoosyAppType *)newAppType;
- (void)didUpdateAppType:(SBChoosyAppType *)existingAppType withNewAppType:(SBChoosyAppType *)updatedAppType;
- (NSArray *)didDownloadAppIcon:(UIImage *)appIcon forAppType:(NSString *)appType;

@optional

@end

@interface SBChoosyBrainz : NSObject

@property (nonatomic, weak) id<SBChoosyBrainzDelegate> delegate;

- (SBChoosyAppType *)appTypeWithKey:(NSString *)appTypeKey;

- (NSArray *)installedAppsForAppType:(SBChoosyAppType *)appType;

/**
 *  This is where the most important logic lives. 
 *  For each app type, checks the cache for
 *  list of apps for given app type, and if cache doesn't exist yet or has expired,
 *  pulls list of top apps for given app type from the server. 
 *
 *  It then checks which of the apps in the list are installed,
 *  and if the previously-selected favorite app (if any) has been deleted.
 *  If new apps for app type have been installed, or the favorite app is no longer installed, 
 *  it sets a flag to force app selection interface.
 *
 *  Next, it checks cache for app icon for each of the detected apps. 
 *  If no icon is present or cache expired, it downloads new icon in the background.
 *
 *  @param appTypes Array of strings where each string is the name of App Type.
 *  @return A list of app types that couldn't be found on the server (invalid types).
 */
- (void)prepareDataForAppTypes:(NSArray *)appTypes;

/**
 *  Retrieves app icon for a given app. If the icon is not in cache and the cache isn't expired, 
 *  it downloads the icon; otherwise, cached version is used.
 *
 *  @param appKey       A string that uniquely identifies the app
 *  @param completionBlock Block to execute once app icon is retrieved
 *
 *  @return App icon
 */
- (UIImage *)appIconForAppKey:(NSString *)appKey completion:(void (^)())completionBlock;

- (void)takeStockOfApps;

- (SBChoosyAppInfo *)defaultAppForAppType:(NSString *)appTypeKey;
- (void)setDefaultAppForAppType:(NSString *)appTypeKey withKey:(NSString *)appKey;
- (BOOL)isAppInstalled:(SBChoosyAppInfo *)app;
- (NSArray *)newAppsForAppType:(NSString *)appTypeKey;

- (NSURL *)urlForAction:(SBChoosyActionContext *)actionContext targetingApp:(NSString *)appKey;

@end
