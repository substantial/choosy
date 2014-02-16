
#import "SBChoosyActionContext.h"

@implementation SBChoosyActionContext

+ (instancetype)createWithAppType:(NSString *)appTypeKey
                           action:(NSString *)actionKey
                       parameters:(NSDictionary *)parameters
                    appPickerText:(NSString *)appPickerText
{
    SBChoosyActionContext *actionContext = [SBChoosyActionContext new];
    
    actionContext.appTypeKey = [appTypeKey lowercaseString];
    actionContext.actionKey = actionKey;
    actionContext.parameters = parameters;
    actionContext.appPickerText = appPickerText;
    
    return actionContext;
}

+ (instancetype)contextWithAppType:(NSString *)appTypeKey
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:nil parameters:nil appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:nil appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerText:nil];
}

+ (instancetype)contextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters appPickerText:(NSString *)appPickerText
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerText:appPickerText];
}

@end
