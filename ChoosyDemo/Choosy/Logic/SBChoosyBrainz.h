// This object manages app lists and app icons (downloads, cache)

#import <Foundation/Foundation.h>

@protocol SBChoosyBrainzDelegate <NSObject>

@required
- (void)didDownloadAppList;
- (void)didDownloadAppIcon:(UIImage *)appIcon forAppType:(NSString *)appType;

@optional

@end

@interface SBChoosyBrainz : NSObject

@property (nonatomic, weak) id<SBChoosyBrainzDelegate> delegate;

- (void)detectAppsForAppTypes:(NSArray *)appTypes; // array of strings, each string is app type name
- (UIImage *)appIconForAppKey:(NSString *)appKey; // app key is a string that uniquely identified an app

@end
