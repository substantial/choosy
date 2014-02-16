
#import "SBChoosyNetworkStore.h"
#import "SBChoosySerialization.h"
#import "NSString+Network.h"

@implementation SBChoosyNetworkStore

// TODO: add a queue and checks to avoid sending duplicate requests for the same app type key

#pragma Public

+ (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(AFHTTPRequestOperation *operation, SBChoosyAppType *downloadedAppType))successBlock
{
    [[SBChoosyNetworkStore new] downloadAppType:appTypeKey success:successBlock];
}

#pragma Private

- (void)downloadAppType:(NSString *)appTypeKey success:(void (^)(AFHTTPRequestOperation *operation, SBChoosyAppType *downloadedAppType))successBlock
{
    AFHTTPRequestOperationManager *requestManager = [AFHTTPRequestOperationManager manager];
    NSString *fileUrl = [self urlFromAppTypeKey:appTypeKey];
    
    // github returns text/plain content type for raw file data, whether the file is .json or not,
    // so tell AFNetworking to be chill when it's that content type
    NSMutableSet *contentTypes = [requestManager.responseSerializer.acceptableContentTypes mutableCopy];
    [contentTypes addObject:@"text/plain"];
    requestManager.responseSerializer.acceptableContentTypes = [contentTypes copy];
    
    [requestManager GET:fileUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSArray *appTypes = [SBChoosySerialization deserializeAppTypesFromJSON:responseObject];
        SBChoosyAppType *appType = [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
        
        if (successBlock) {
            successBlock(operation, appType);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error getting JSON file: %@", error);
    }];
}
                                                                              
- (NSString *)urlFromAppTypeKey:(NSString *)appTypeKey
{
    NSString *fileUrl = [NSString stringWithFormat:@"https://raw.github.com/substantial/choosy/master/app-data/%@.json", [[appTypeKey urlEncodeUsingEncoding:NSUTF8StringEncoding] lowercaseString]];
    return fileUrl;
}
                         
@end
