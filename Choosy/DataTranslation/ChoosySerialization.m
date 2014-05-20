#import "ChoosySerialization.h"
#import "MTLJSONAdapter.h"

@implementation ChoosySerialization

#pragma mark Public

+ (NSArray *)deserializeAppTypesFromNSData:(NSData *)jsonFormatData
{
    NSError *error;
    NSArray *appTypesJSON = [NSJSONSerialization JSONObjectWithData:jsonFormatData options:0 error:&error];
    if (error) {
        NSLog(@"Couldn't deserealize app type JSON from NSData: %@", error);
        return nil;
    }
    
    return [ChoosySerialization deserializeAppTypesFromJSON:appTypesJSON];
}

+ (NSArray *)deserializeAppTypesFromJSON:(NSArray *)appTypesJSON
{
    NSError *error;
    NSArray *appTypes = [MTLJSONAdapter modelsOfClass:[ChoosyAppType class] fromJSONArray:appTypesJSON error:&error];
    if (error) {
        NSLog(@"Couldn't convert app types JSON to ChoosyAppType models: %@", error);
        return nil;
    }

    return appTypes;
}

+ (NSData *)serializeAppTypesToNSData:(NSArray *)appTypes
{
    NSArray *appTypesJSON = [MTLJSONAdapter JSONArrayFromModels:appTypes];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:appTypesJSON options:0 error:&error];
    if (error) {
        NSLog(@"Couldn't turn app types JSON into NSData. JSON: %@, \n\n Error: %@", appTypesJSON, error);
        return nil;
    }
    
    return jsonData;
}

@end
