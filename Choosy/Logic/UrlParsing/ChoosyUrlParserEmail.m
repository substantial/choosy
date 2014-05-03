//
//  ChoosyUrlParserEmail.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyUrlParserEmail.h"

@implementation ChoosyUrlParserEmail

- (ChoosyActionContext *)parseUrl:(NSURL *)url
{
    ChoosyActionContext *actionContext;
    
    actionContext = [ChoosyActionContext actionContextWithAppType:@"Email"];
    
    return actionContext;
}

@end
