//
//  SBChoosyUrlParserFactory.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyUrlParserFactory.h"
#import "SBChoosyUrlParserTwitter.h"
//#import "SBChoosyUrlParserWeb.h"
//#import "SBChoosyUrlParserMaps.h"

@implementation SBChoosyUrlParserFactory

+ (id<SBChoosyUrlParser>)parserForUrl:(NSURL *)url
{
    NSString *scheme = [[url scheme] lowercaseString];
    NSString *host = [[url host] lowercaseString];
    
    id<SBChoosyUrlParser> parser;
    if ([host isEqualToString:@"twitter.com"] || [scheme isEqualToString:@"twitter"]) {
        parser = [SBChoosyUrlParserTwitter new];
    } // todo
    
    return parser;
}

@end
