//
//  SBChoosyUrlParserTwitter.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyUrlParserTwitter.h"

@implementation SBChoosyUrlParserTwitter

- (SBChoosyActionContext *)parseUrl:(NSURL *)url
{
    SBChoosyActionContext *actionContext;
    
    actionContext = [SBChoosyActionContext actionContextWithAppType:@"Twitter"
                                                             action:@"show_profile"
                                                         parameters:@{@"profile_screenname": [url pathComponents][1]} ];

    
    return actionContext;
}

@end
