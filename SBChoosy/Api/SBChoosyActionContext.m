
#import "SBChoosyActionContext.h"
#import "SBChoosyUrlParserFactory.h"

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

+ (instancetype)actionContextWithUrl:(NSURL *)url
{
    SBChoosyActionContext *actionContext;
    
    // get parser from the factory
    id<SBChoosyUrlParser> urlParser = [SBChoosyUrlParserFactory parserForUrl:url];
    
    // parse
    actionContext = [urlParser parseUrl:url];
    
    return actionContext;
}

@end
