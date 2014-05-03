
#import <Foundation/Foundation.h>
#import "ChoosyPickerAppTypeInfo.h"

@interface ChoosyPickerViewModel : NSObject

@property (nonatomic) ChoosyPickerAppTypeInfo *appTypeInfo;
@property (nonatomic) NSString *pickerTitleText;
@property (nonatomic) NSString *pickerText;
@property (nonatomic) BOOL allowDefaultAppSelection;

@end
