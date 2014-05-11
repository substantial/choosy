
#import "ChoosyNetworkStore.h"
#import "ChoosySerialization.h"
#import "ChoosyAppInfo.h"
#import "NSString+Network.h"
#import "ChoosyLocalStore.h"

static NSMutableArray *_appKeysForIconsBeingDownloaded;

@implementation ChoosyNetworkStore

// TODO: add a queue and checks to avoid sending duplicate requests for the same app type key

#pragma Public

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(ChoosyAppType *downloadedAppType))successBlock failure:(void(^)(NSError *error))failureBlock
{
    [[ChoosyNetworkStore new] downloadAppType:appTypeKey success:successBlock failure:failureBlock];
}

+ (void)downloadAppIconForAppKey:(NSString *)appKey success:(void (^)(UIImage *))successBlock failure:(void (^)(NSError *error))failureBlock
{
    [[ChoosyNetworkStore new] downloadAppIconForAppKey:appKey success:successBlock failure:failureBlock];
}

#pragma Private

- (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(ChoosyAppType *downloadedAppType))successBlock failure:(void(^)(NSError *error))failureBlock
{
    NSString *fileUrl = [self urlForAppTypeData:appTypeKey];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    
    // Choosy handles caching internally;
    // so when it asks for data, we want to make sure it's real, up-to-date data from the server
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    [[session dataTaskWithRequest:[request copy] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // TODO: on error, if b/c no connection, subscribe to the Connection now Available notification, and pull data when that occurs :P
        if (error) {
            NSLog(@"Error downloading app type data for type '%@'. DATA: %@. RESPONSE: %@. ERROR: %@", appTypeKey, data, response, error);
            if (failureBlock) {
                failureBlock(error);
            }
            return;
        }
        
        NSArray *appTypes = [ChoosySerialization deserializeAppTypesFromNSData:data];
        ChoosyAppType *appType = [ChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
        
        if (appType) {
            if (successBlock) {
                successBlock(appType);
            }
        } else {
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Download of app type unsuccessful.", nil),
                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"File for the app type was downloaded, but the app type was not found inside of it.", nil),
                                       NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Check that app type key is spelled correctly inside the file", nil)
                                       };
            NSError *customError = [NSError errorWithDomain:@"com.substantial.choosy" code:1 userInfo:userInfo];
            
            NSLog(@"Download of app type '%@' failed: file for it did download, but app type with that key not found inside.", appTypeKey);
            if (failureBlock) {
                failureBlock(customError);
            }
        }
    }] resume];
}

- (void)downloadAppIconForAppKey:(NSString *)appKey success:(void (^)(UIImage *))successBlock failure:(void (^)(NSError *))errorBlock
{
    if ([_appKeysForIconsBeingDownloaded containsObject:appKey]) {
        // aleady downloading app icon for this app key
        return;
    }
    
    @synchronized(self) {
        if (!_appKeysForIconsBeingDownloaded) {
            _appKeysForIconsBeingDownloaded = [NSMutableArray new];
        }
        [_appKeysForIconsBeingDownloaded addObject:appKey];
    }
    
    NSString *fileUrl = [self urlForAppIcon:appKey];
    
    NSLog(@"Downloading app icon for app key: %@, at file URL: %@", appKey, fileUrl);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    
    // Choosy handles caching internally;
    // so when it asks for data, we want to make sure it's real, up-to-date data from the server
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    [[session dataTaskWithRequest:[request copy] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [_appKeysForIconsBeingDownloaded removeObject:appKey];
        if ([_appKeysForIconsBeingDownloaded count] == 0) {
            _appKeysForIconsBeingDownloaded = nil; // clean up static variable if all downloads finished
        }
        
        // TODO: on error, subscribe to the Connection now Available notification, and pull data when that occurs :P
        if (error) {
            NSLog(@"Error downloading app icon for app '%@'. DATA: %@. RESPONSE: %@. ERROR: %@", appKey, data, response, error);
            return;
        };
        
//        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
//        NSInteger statusCode = [httpResponse statusCode];
//        NSDictionary *headers = [httpResponse allHeaderFields];
//        NSString *responseExpirationDate = headers[@"Expires"];
        
        UIImage *appIcon = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
        
        if (successBlock) {
            successBlock(appIcon);
        }
    }] resume];
}

- (NSString *)urlForAppTypeData:(NSString *)appTypeKey
{
    NSString *fileUrl = [NSString stringWithFormat:@"https://raw.githubusercontent.com/gamenerds/choosy-data/master/app-data/%@.json", appTypeKey];
    return fileUrl;
}

- (NSString *)urlForAppIcon:(NSString *)appKey
{
    NSString *appIconName = [ChoosyLocalStore appIconFileNameForAppKey:appKey];
    NSString *fileUrl = [NSString stringWithFormat:@"https://raw.githubusercontent.com/substantial/choosy-data/master/app-icons/%@", appIconName];
    return fileUrl;
}

@end
