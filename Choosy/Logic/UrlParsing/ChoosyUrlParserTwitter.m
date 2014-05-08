//
//  ChoosyUrlParserTwitter.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyUrlParserTwitter.h"

@implementation ChoosyUrlParserTwitter

- (ChoosyActionContext *)parseUrl:(NSURL *)url
{
    ChoosyActionContext *actionContext;
    
    // TODO: like, turn this into real code and stuff... but this will do for beta/testing
    actionContext = [ChoosyActionContext actionContextWithAppType:@"Twitter"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSMutableArray *pathComponents = [NSMutableArray new];
    for (NSString *pathComponent in [url pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) {
            continue;
        }
        
        [pathComponents addObject:pathComponent];
    }
    
    if ([pathComponents count] == 1) {
        actionContext.actionKey = @"show_profile";
        [parameters setObject:pathComponents[0] forKey:@"profile_screenname"];
    }
    
    actionContext.parameters = [parameters copy];
    
    return actionContext;
}

@end
