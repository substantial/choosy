//
//  SBChoosyUrlParserEmail.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyUrlParserEmail.h"

@implementation SBChoosyUrlParserEmail

- (SBChoosyActionContext *)parseUrl:(NSURL *)url
{
    SBChoosyActionContext *actionContext;
    
    actionContext = [SBChoosyActionContext actionContextWithAppType:@"Email"];
    
    return actionContext;
}

@end
