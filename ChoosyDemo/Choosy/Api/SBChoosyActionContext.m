
#import "SBChoosyActionContext.h"

@implementation SBChoosyActionContext

+ (instancetype)createWithAppType:(NSString *)appType
                           action:(NSString *)action
                       parameters:(NSDictionary *)parameters
                    appPickerText:(NSString *)appPickerText
{
    SBChoosyActionContext *actionContext = [SBChoosyActionContext new];
    
    actionContext.appType = appType;
    actionContext.action = action;
    actionContext.parameters = parameters;
    actionContext.appPickerText = appPickerText;
    
    return actionContext;
}

+ (instancetype)contextWithAppType:(NSString *)appType
{
    return [SBChoosyActionContext createWithAppType:appType action:nil parameters:nil appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action
{
    return [SBChoosyActionContext createWithAppType:appType action:action parameters:nil appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action parameters:(NSDictionary *)parameters
{
    return [SBChoosyActionContext createWithAppType:appType action:action parameters:parameters appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appType action:(NSString *)action parameters:(NSDictionary *)parameters appPickerText:(NSString *)appPickerText
{
    return [SBChoosyActionContext createWithAppType:appType action:action parameters:parameters appPickerText:appPickerText];
}

@end
