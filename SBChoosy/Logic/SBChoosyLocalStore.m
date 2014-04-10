
#import "SBChoosyLocalStore.h"
#import "SBChoosySerialization.h"

static NSString *LAST_DETECTED_APPS_KEY = @"DetectedApps";
static NSString *DEFAULT_APPS_KEY = @"DefaultApps";

@implementation SBChoosyLocalStore

#pragma mark - Public

#pragma mark Default App Selection

+ (NSString *)defaultAppForAppTypeKey:(NSString *)appType
{
    NSDictionary *defaultApps = [(NSMutableDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_APPS_KEY] copy];
    
    return defaultApps[appType];
}

+ (void)setDefaultApp:(NSString *)appKey forAppTypeKey:(NSString *)appType
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *defaultApps = [(NSDictionary *)[defaults objectForKey:DEFAULT_APPS_KEY] mutableCopy];
    
    if (!defaultApps) defaultApps = [NSMutableDictionary new];
    
    if (appKey) {
        defaultApps[appType] = appKey;
    } else {
        if ([defaultApps.allKeys containsObject:appType]) [defaultApps removeObjectForKey:appType];
    }
    
	[defaults setObject:defaultApps forKey:DEFAULT_APPS_KEY];
	[defaults synchronize];
}

#pragma mark Last Detected Apps

+ (NSArray *)lastDetectedAppKeysForAppTypeWithKey:(NSString *)appTypeKey
{
	NSDictionary *detectedApps = (NSDictionary *)[[NSUserDefaults standardUserDefaults] objectForKey:LAST_DETECTED_APPS_KEY];
    
    if (detectedApps) {
        return detectedApps[appTypeKey];
    }
    
    return nil;
}

+ (void)setLastDetectedAppKeys:(NSArray *)appKeys forAppTypeKey:(NSString *)appTypeKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *detectedApps = (NSDictionary *)[defaults objectForKey:LAST_DETECTED_APPS_KEY];
    
    NSMutableDictionary *newDetectedApps = detectedApps ? [detectedApps mutableCopy] : [NSMutableDictionary new];
    newDetectedApps[appTypeKey] = appKeys;
    
	[defaults setObject:[newDetectedApps copy] forKey:LAST_DETECTED_APPS_KEY];
	[defaults synchronize];
}

#pragma mark App Type Caching

+ (NSArray *)cachedAppTypes
{
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathForCacheDirectory] error:nil];
    NSPredicate *jsonExtFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.json'"];
    NSArray *jsonFilePaths = [directoryContents filteredArrayUsingPredicate:jsonExtFilter];
    
    NSMutableArray *appTypes = [NSMutableArray new];
    for (NSString *jsonFilePath in jsonFilePaths) {
        [appTypes addObjectsFromArray:[self cachedAppTypesAtPath:jsonFilePath]];
    }
    
    return [appTypes count] > 0 ? appTypes : nil;
}

+ (SBChoosyAppType *)cachedAppType:(NSString *)appTypeKey;
{
    NSString *filePath = [self filePathForAppTypeKey:appTypeKey];
    NSArray *appTypes = [self cachedAppTypesAtPath:filePath];
    
    return [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

+ (void)cacheAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    // TODO: make sure this runs on a background thread
    
    // convert app types to JSON
    for (SBChoosyAppType *appType in appTypes) {
        if (!appType.dateUpdated) {
            appType.dateUpdated = [NSDate date];
        }
        NSData *appTypeData = [SBChoosySerialization serializeAppTypesToNSData:@[appType]];
        NSString *filePath = [self filePathForAppTypeKey:appType.key];
        
//        NSError *error;
        [appTypeData writeToFile:filePath atomically:YES];
    }
}

+ (SBChoosyAppType *)builtInAppType:(NSString *)appTypeKey
{
    NSString *filePath = [self filePathForBundledFileNamed:@"systemAppTypes" ofType:@"json"];
    
    NSArray *appTypes = [SBChoosyLocalStore cachedAppTypesAtPath:filePath];
    
    return [SBChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

+ (BOOL)appIconExistsForAppKey:(NSString *)appKey
{
    // TODO: background thread
    // check if amid system app icons
    NSString *fileName = [SBChoosyAppInfo appIconFileNameWithoutExtensionForAppKey:appKey];
    NSString *fileExtension = [SBChoosyAppInfo appIconFileExtension];
    NSString *builtInAppIconPath = [self filePathForBundledFileNamed:fileName ofType:fileExtension];
    
    if (builtInAppIconPath) return YES;
    
    // check cache
    NSString *filePath = [self filePathForAppIconForAppKey:appKey];
    if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

+ (UIImage *)appIconForAppKey:(NSString *)appKey
{
    // TODO: background thread
    // check if amid system app icons
    UIImage *appIcon = [UIImage imageNamed:[SBChoosyAppInfo appIconFileNameForAppKey:appKey]];
    if (appIcon) return appIcon;
    
    // check amid cached icons
    NSString *filePath = [SBChoosyLocalStore filePathForAppIconForAppKey:appKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        appIcon = [UIImage imageWithContentsOfFile:filePath];
    }
    
    return appIcon;
}

+ (void)cacheAppIcon:(UIImage *)appIcon forAppKey:(NSString *)appKey
{
    NSString *path = [self filePathForAppIconForAppKey:appKey];
    NSData *imageData = UIImagePNGRepresentation(appIcon);
    
    [imageData writeToFile:path atomically:YES];
    
    NSLog(@"Cached app icon for %@ at path %@", appKey, path);
}

+ (NSString *)filePathForBundledFileNamed:(NSString *)fileName ofType:(NSString *)fileType
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    if (!filePath) {
        NSBundle *resourcesBundle = [NSBundle bundleWithIdentifier:@"SBChoosyResources"];
        filePath = [resourcesBundle pathForResource:fileName ofType:fileType];
    }
    
    return filePath;
}

#pragma mark - Private
#pragma mark App Type Caching

+ (NSArray *)cachedAppTypesAtPath:(NSString *)filePath
{
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) return nil;
    
    NSData *jsonAppTypeData = [[NSFileManager defaultManager] contentsAtPath:filePath];
    
    NSArray *appTypes = [SBChoosySerialization deserializeAppTypesFromNSData:jsonAppTypeData];
    
    return appTypes;
}

+ (NSString *)filePathForAppTypeKey:(NSString *)appTypeKey
{
    return [[self pathForCacheDirectory] stringByAppendingPathComponent:[appTypeKey stringByAppendingString:@".json"]];
}

+ (NSString *)pathForCacheDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Choosy"];
    BOOL isDir = NO;
    NSError *error;
    if (! [[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir] && isDir == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    return cachePath;
}

#pragma mark App Icon Caching

+ (NSString *)filePathForAppIconForAppKey:(NSString *)appKey
{
    return [[self pathForCacheDirectory] stringByAppendingPathComponent:[SBChoosyAppInfo appIconFileNameForAppKey:appKey]];
}

@end
