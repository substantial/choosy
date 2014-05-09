
#import <Foundation/Foundation.h>

/*
 Used to define a specific action in Choosy
 */
@interface ChoosyActionContext : NSObject

// required
@property (nonatomic) NSString *appTypeKey;

// optional
@property (nonatomic) NSString *actionKey;
@property (nonatomic) NSDictionary *parameters;
@property (nonatomic) NSString *appPickerTitle; // overrides the default title in App Picker UI

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey;
+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey;
+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters;
+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters appPickerTitle:(NSString *)appPickerTitle;

/**
 * Parses given URL to determine app type and base parameters.
 * Additional parameters, if any, can be added to the returned ChoosyActionContext instance.
 *
 *  @param url The url in question, such as one web view is attempting to navigate to.
 *
 *  @return An instance of ChoosyActionContext
 */
+ (instancetype)actionContextWithUrl:(NSURL *)url;

@end
