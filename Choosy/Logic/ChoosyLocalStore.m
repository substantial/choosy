
#import "ChoosyGlobals.h"
#import "ChoosyLocalStore.h"
#import "ChoosySerialization.h"
#import "UIImage+ImageEffects.h"

static NSString *LAST_DETECTED_APPS_KEY = @"DetectedApps";
static NSString *DEFAULT_APPS_KEY = @"DefaultApps";

@implementation ChoosyLocalStore

static NSString *_appIconFileExtension = @"png";

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

#pragma mark App Type

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

+ (ChoosyAppType *)cachedAppType:(NSString *)appTypeKey;
{
    NSString *filePath = [self filePathForAppTypeKey:appTypeKey];
    NSArray *appTypes = [self cachedAppTypesAtPath:filePath];
    
    return [ChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

+ (void)cacheAppTypes:(NSArray *)appTypes
{
    if (!appTypes) return;
    
    // convert app types to JSON
    for (ChoosyAppType *appType in appTypes) {
        [self cacheAppType:appType];
   }
}

+ (void)cacheAppType:(ChoosyAppType *)appType
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (!appType.dateUpdated) {
            appType.dateUpdated = [NSDate date];
        }
        
        NSData *appTypeData = [ChoosySerialization serializeAppTypesToNSData:@[appType]];
        NSString *filePath = [ChoosyLocalStore filePathForAppTypeKey:appType.key];
        
        [appTypeData writeToFile:filePath atomically:YES];
    });
}

+ (ChoosyAppType *)builtInAppType:(NSString *)appTypeKey
{
    NSString *filePath = [self filePathForBundledFileNamed:@"systemAppTypes" ofType:@"json"];
    
    NSArray *appTypes = [ChoosyLocalStore cachedAppTypesAtPath:filePath];
    
    return [ChoosyAppType filterAppTypesArray:appTypes byKey:appTypeKey];
}

#pragma mark App Icon

+ (BOOL)appIconExistsForAppKey:(NSString *)appKey
{
    // TODO: background thread
    
    // check if amid system app icons
    NSString *builtInAppIconPath = [self filePathForBundledAppIconForAppKey:appKey];
    if (builtInAppIconPath) return YES;
    
    // check cache
    NSString *filePath = [self filePathForCachedAppIconForAppKey:appKey];
    if (filePath && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return YES;
    }
    
    return NO;
}

+ (NSString *)filePathForBundledAppIconForAppKey:(NSString *)appKey
{
    NSString *fileName = [self fileNameWithoutExtensionForImageNamed:appKey];
    NSString *fileExtension = [self appIconFileExtension];
    NSString *builtInAppIconPath = [self filePathForBundledFileNamed:fileName ofType:fileExtension];
    
    return builtInAppIconPath;
}

+ (UIImage *)appIconForAppKey:(NSString *)appKey
{
    // TODO: background thread
    
    // check if amid system app icons
    UIImage *appIcon = [UIImage imageWithContentsOfFile:[self filePathForBundledAppIconForAppKey:appKey]];
    if (appIcon) {
        // mask system icons so that they have rounded corners when displayed
        return [appIcon applyMaskImage:[self appIconMask]];
    }
    
    // check amid cached icons, these should already be masked with rounded corners
    NSString *filePath = [ChoosyLocalStore filePathForCachedAppIconForAppKey:appKey];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        appIcon = [UIImage imageWithContentsOfFile:filePath];
    }
    
    return appIcon;
}

+ (UIImage *)appIconMask
{
    NSString *iconMaskFileName = [self fileNameWithoutExtensionForImageNamed:@"iconMask"];
    UIImage *iconMask = [UIImage imageWithContentsOfFile:[self filePathForBundledFileNamed:iconMaskFileName ofType:@"png"]];
    
    return iconMask;
}

+ (void)cacheAppIcon:(UIImage *)appIcon forAppKey:(NSString *)appKey
{
    if (!appIcon) {
        return;
    }
    
    NSString *path = [self filePathForCachedAppIconForAppKey:appKey];
    NSData *imageData = UIImagePNGRepresentation(appIcon);
    
    [imageData writeToFile:path atomically:YES];
    
    NSLog(@"Cached app icon for %@ at path %@", appKey, path);
}


+ (NSString *)appIconFileNameForAppKey:(NSString *)appKey
{
    // TODO: what if scale goes up to @3x or @4x? We need to then show previous-X icons such as @2x.
    NSString *appIconName = [self fileNameWithoutExtensionForImageNamed:appKey];
    
    appIconName = [[appIconName stringByAppendingString:@"."] stringByAppendingString:[self appIconFileExtension]];
    
    return appIconName;
}

+ (NSString *)fileNameWithoutExtensionForImageNamed:(NSString *)imageName
{
    // add suffix for retina screens, ex: safari@2x.png
    NSInteger scale = (NSInteger)[[UIScreen mainScreen] scale];
    
    if (scale > 1) imageName = [imageName stringByAppendingFormat:@"@%ldx", (long)scale];
    
    return imageName;
}

+ (NSString *)appIconFileExtension
{
    return _appIconFileExtension;
}

+ (NSString *)filePathForBundledFileNamed:(NSString *)fileName ofType:(NSString *)fileType
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    if (!filePath) {
        NSBundle *resourcesBundle = [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"ChoosyResources.bundle"]];
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
    
    NSArray *appTypes = [ChoosySerialization deserializeAppTypesFromNSData:jsonAppTypeData];
    
    return appTypes;
}

+ (NSString *)filePathForAppTypeKey:(NSString *)appTypeKey
{
    return [[ChoosyLocalStore pathForCacheDirectory] stringByAppendingPathComponent:[appTypeKey stringByAppendingString:@".json"]];
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

+ (NSString *)filePathForCachedAppIconForAppKey:(NSString *)appKey
{
    return [[self pathForCacheDirectory] stringByAppendingPathComponent:[self appIconFileNameForAppKey:appKey]];
}

@end
