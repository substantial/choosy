
#import "ChoosyActionContext.h"
#import "ChoosyUrlParserFactory.h"

@implementation ChoosyActionContext

+ (instancetype)createWithAppType:(NSString *)appTypeKey
                           action:(NSString *)actionKey
                       parameters:(NSDictionary *)parameters
                    appPickerTitle:(NSString *)appPickerTitle
{
    ChoosyActionContext *actionContext = [ChoosyActionContext new];
    
    actionContext.appTypeKey = [appTypeKey lowercaseString];
    actionContext.actionKey = [actionKey lowercaseString];
    actionContext.parameters = parameters;
    actionContext.appPickerTitle = appPickerTitle;
    
    return actionContext;
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey
{
    return [ChoosyActionContext createWithAppType:appTypeKey action:nil parameters:nil appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey
{
    return [ChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:nil appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters
{
    return [ChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerTitle:nil];
}

+ (instancetype)actionContextWithAppType:(NSString *)appTypeKey action:(NSString *)actionKey parameters:(NSDictionary *)parameters appPickerTitle:(NSString *)appPickerTitle
{
    return [ChoosyActionContext createWithAppType:appTypeKey action:actionKey parameters:parameters appPickerTitle:appPickerTitle];
}

+ (instancetype)actionContextWithUrl:(NSURL *)url
{
    ChoosyActionContext *actionContext;
    
    // get parser from the factory
    id<ChoosyUrlParser> urlParser = [ChoosyUrlParserFactory parserForUrl:url];
    
    // parse
    actionContext = [urlParser parseUrl:url];
    
    return actionContext;
}

@end
