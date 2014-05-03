//
//  SBChoosyUrlParserTwitter.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyUrlParserTwitter.h"
#import "NSArray+ObjectiveSugar.h"

@implementation SBChoosyUrlParserTwitter

- (SBChoosyActionContext *)parseUrl:(NSURL *)url
{
    SBChoosyActionContext *actionContext;
    
    // TODO: like, turn this into real code and stuff... but this will do for beta/testing
    actionContext = [SBChoosyActionContext actionContextWithAppType:@"Twitter"];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSArray *pathComponents = [[url pathComponents] reject:^BOOL(id object) {
        if ([(NSString *)object isEqualToString:@"/"]) {
            return YES;
        }
        
        return NO;
    }];
    
    if ([pathComponents count] == 1) {
        actionContext.actionKey = @"show_profile";
        [parameters setObject:pathComponents[0] forKey:@"profile_screenname"];
    }
    
    actionContext.parameters = [parameters copy];
    
    return actionContext;
}

@end
