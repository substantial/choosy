//
//  ChoosyUrlCreator.m
//  Pods
//
//  Created by Sasha Novosad on 5/9/14.
//
//

#import "ChoosyUrlCreator.h"
#import "ChoosyActionContext.h" 
#import "ChoosyAppInfo.h" 
#import "ChoosyAppType.h" 
#import "ChoosyAppAction.h"
#import "ChoosyAppTypeParameter.h"

@implementation ChoosyUrlCreator

+ (NSURL *)urlForAction:(ChoosyActionContext *)actionContext targetingApp:(ChoosyAppInfo *)appInfo inAppType:(ChoosyAppType *)appType
{
    // does the app support this action?
    ChoosyAppAction *action = [appInfo findActionWithKey:actionContext.actionKey];
    
    NSURL *url = [self urlForAction:action withActionParams:actionContext.parameters appTypeParams:appType.parameters];
    
    return  url ? url : appInfo.appURLScheme;
}

+ (NSURL *)urlForAction:(ChoosyAppAction *)action withActionParams:(NSDictionary *)actionParams appTypeParams:(NSArray *)appTypeParams
{
    // separate the part of URL scheme before "?" from the part after
    NSString *urlSchemeFormat = action.urlFormat;
    
    if (!urlSchemeFormat) {
        NSLog(@"Failed to create url for action '%@' because action's url format is not specified", action.actionKey);
    }
    
    NSString *urlStringWithPlaceholders = [urlSchemeFormat componentsSeparatedByString:@"?"][0];
    
    // if any parameters appear in the URL scheme prior to the query string,
    // we just replace their placeholders with a value or, if no value, an empty string
    NSString *urlStringWithValues = [self replacePlaceholdersInString:urlStringWithPlaceholders usingActionParams:actionParams appTypeParams:appTypeParams];
    
    // final query string should only contain keys that have values
    NSString *queryStringWithValues = [self queryStringFromUrlSchemeFormat:urlSchemeFormat actionParams:actionParams appTypeParams:appTypeParams];
    
    // combine the pieces
    if ([queryStringWithValues length] > 0) {
        urlStringWithValues = [[urlStringWithValues stringByAppendingString:@"?"] stringByAppendingString:queryStringWithValues];
    }
    
    return [NSURL URLWithString:urlStringWithValues];
}

+ (NSString *)queryStringFromUrlSchemeFormat:(NSString *)urlSchemeFormat actionParams:(NSDictionary *)actionParams appTypeParams:(NSArray *)appTypeParams
{
    NSArray *urlComponents = [urlSchemeFormat componentsSeparatedByString:@"?"];
    if ([urlComponents count] <= 1) return nil;
    
    NSString *queryStringWithPlaceholders = urlComponents[1];
    
    // grab only the query parameters that have values
    NSMutableArray *processedQueryParameters = [NSMutableArray new];
    for (NSString *queryParamWithPlaceholder in [queryStringWithPlaceholders componentsSeparatedByString:@"&"]) {
        NSArray *queryParamComponents = [queryParamWithPlaceholder componentsSeparatedByString:@"="];
        NSString *paramKey = queryParamComponents[0];
        NSString *paramValue = queryParamComponents[1];
        
        paramValue = [self replacePlaceholdersInString:paramValue usingActionParams:actionParams appTypeParams:appTypeParams];
        
        if ([paramValue length] > 0) {
            NSString *newQueryParam = [[paramKey stringByAppendingString:@"="] stringByAppendingString:paramValue];
            [processedQueryParameters addObject:newQueryParam];
        }
    }
    
    // compose the final query parameters
    NSString *queryStringWithValues = @"";
    if ([processedQueryParameters count] > 0) {
        for (NSString *queryParam in processedQueryParameters) {
            if ([queryStringWithValues length] > 0) {
                queryStringWithValues = [queryStringWithValues stringByAppendingString:@"&"];
            }
            
            queryStringWithValues = [queryStringWithValues stringByAppendingString:queryParam];
        }
    }

    return queryStringWithValues;
}

+ (NSString *)replacePlaceholdersInString:(NSString *)urlString usingActionParams:(NSDictionary *)actionParams appTypeParams:(NSArray *)appTypeParams
{
    for (ChoosyAppTypeParameter *appTypeParameter in appTypeParams) {
        NSString *parameterValue = @"";
        NSString *parameterKey = [appTypeParameter.key lowercaseString];
        if ([actionParams.allKeys containsObject:parameterKey]) {
            parameterValue = actionParams[parameterKey];
            parameterValue = [parameterValue stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSString *paramPlaceholder = [[@"{{" stringByAppendingString:parameterKey] stringByAppendingString:@"}}"];
        urlString = [urlString stringByReplacingOccurrencesOfString:paramPlaceholder withString:parameterValue];
    }
    
    return urlString;
}

@end
