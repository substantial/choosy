
#import "SBChoosyActionContext.h"

@implementation SBChoosyActionContext

+ (instancetype)createWithAppType:(NSString *)appTypeKey
                           action:(NSString *)actionKey
                       parameters:(NSDictionary *)parameters
                    appPickerTitle:(NSString *)appPickerTitle
{
    SBChoosyActionContext *actionContext = [SBChoosyActionContext new];
    
    actionContext.appTypeKey = [appTypeKey lowercaseString];
    actionContext.actionKey = [actionKey lowercaseString];
    actionContext.parameters = parameters;
    actionContext.appPickerTitle = appPickerTitle;
    
    return actionContext;
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:nil parameters:nil appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:nil appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters appPickerTitle:(NSString *)appPickerTitle
{
    return [SBChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerTitle:appPickerTitle];
}

//+ (instancetype)actionContextWithUrl:(NSURLRequest *)url
//{
//    
//}

@end
