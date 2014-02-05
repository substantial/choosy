
#import <Foundation/Foundation.h>

/*
 Used to define a specific action in Choosy
 */
@interface SBChoosyActionContext : NSObject

// required
@property (nonatomic) NSString *appType;

// optional
@property (nonatomic) NSString *action;
@property (nonatomic) NSDictionary *parameters;
@property (nonatomic) NSString *appPickerText; // overrides the default text in App Picker UI

+ (instancetype)contextWithAppType:(NSString *)appType;
+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action;
+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action parameters:(NSDictionary *)parameters;
+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action parameters:(NSDictionary *)parameters appPickerText:(NSString *)appPickerText;

@end
