
#import <Foundation/Foundation.h>

/*
 Used to define a specific action in Choosy
 */
@interface SBChoosyActionContext : NSObject

// required
@property (nonatomic) NSString *appType;

// optional
@property (nonatomic) NSString *action;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSString *appPickerText; // overrides the default text in App Picker UI

@end
