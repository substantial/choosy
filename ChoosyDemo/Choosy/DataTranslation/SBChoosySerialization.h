
#import <Foundation/Foundation.h>
#import "SBChoosyAppType.h"

@interface SBChoosySerialization : NSObject

/**
 *  Converts NSData into array of SBChoosyAppType objects.
 *
 *  @param jsonFormatData NSData representation of SBChoosyAppType's JSON.
 *
 *  @return Array of SBChoosyAppType objects; nil if no objects found.
 */
+ (NSArray *)deserializeAppTypesFromNSData:(NSData *)jsonFormatData;

+ (NSArray *)deserializeAppTypesFromJSON:(NSArray *)appTypesJSON;

+ (SBChoosyAppType *)deserializeAppTypeFromJSON:(NSDictionary *)appTypeJSON;

+ (NSData *)serializeAppTypesToNSData:(NSArray *)appTypes;

@end
