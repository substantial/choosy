
#import <Foundation/Foundation.h>
#import "SBChoosyPickerAppInfo.h"

@interface SBChoosyPickerAppTypeInfo : NSObject

/**
 *  Array of SBChoosyPickerAppInfo objects.
 */
@property (nonatomic) NSArray *installedApps;

@property (nonatomic) NSString *appTypeName;

@end
