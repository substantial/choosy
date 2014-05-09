#import "ChoosySerialization.h"
#import "MTLJSONAdapter.h"

@implementation ChoosySerialization

#pragma mark Public

+ (NSArray *)deserializeAppTypesFromNSData:(NSData *)jsonFormatData
{
    if (!jsonFormatData) return nil;
    
    NSError *error;
    NSArray *appTypesJSON = [NSJSONSerialization JSONObjectWithData:jsonFormatData options:0 error:&error];
    if (error) {
        NSLog(@"Couldn't deserealize app type JSON from NSData: %@", error);
        error = nil;
    }
    
    return [ChoosySerialization deserializeAppTypesFromJSON:appTypesJSON];
}

+ (NSArray *)deserializeAppTypesFromJSON:(NSArray *)appTypesJSON
{
    if (!appTypesJSON || [appTypesJSON count] == 0) return nil;
    
    NSMutableArray *appTypes = [NSMutableArray new];
    for (NSDictionary *appTypeJSON in appTypesJSON) {
        ChoosyAppType *appType = [ChoosySerialization deserializeAppTypeFromJSON:appTypeJSON];
        
        if (appType) {
            [appTypes addObject:appType];
        }
    }
    
    return [appTypes count] > 0 ? [NSArray arrayWithArray:appTypes] : nil;
}

+ (ChoosyAppType *)deserializeAppTypeFromJSON:(NSDictionary *)appTypeJSON
{
    NSError *error;
    
    ChoosyAppType *appType = [MTLJSONAdapter modelOfClass:[ChoosyAppType class] fromJSONDictionary:appTypeJSON error:&error];
    
    if (error) NSLog(@"Error converting app type JSON into model. JSON: %@ \n\n Error: %@", appTypeJSON, error);
    
    return appType;
}

+ (NSData *)serializeAppTypesToNSData:(NSArray *)appTypes
{
    NSArray *appTypesJSON = [ChoosySerialization serializeAppTypesToJSON:appTypes];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:appTypesJSON options:0 error:&error];
    
    if (error) {
        NSLog(@"Couldn't turn app types JSON into NSData. JSON: %@, \n\n Error: %@", appTypesJSON, error);
        return nil;
    } else {
        return jsonData;
    }
}

#pragma mark Private

+ (NSArray *)serializeAppTypesToJSON:(NSArray *)appTypes
{
    if (!appTypes) return nil;
    
    NSMutableArray *appTypesJSON = [NSMutableArray new];
    
    for (ChoosyAppType *appType in appTypes) {
        NSDictionary *appTypeJSON = [MTLJSONAdapter JSONDictionaryFromModel:appType];
        [appTypesJSON addObject:appTypeJSON];
    }
    
    return appTypesJSON;
}

@end
