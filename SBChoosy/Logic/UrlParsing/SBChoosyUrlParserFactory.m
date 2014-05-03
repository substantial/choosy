//
//  SBChoosyUrlParserFactory.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyUrlParserFactory.h"
#import "SBChoosyUrlParserTwitter.h"
#import "SBChoosyUrlParserEmail.h"
//#import "SBChoosyUrlParserWeb.h"
//#import "SBChoosyUrlParserMaps.h"

@implementation SBChoosyUrlParserFactory

+ (id<SBChoosyUrlParser>)parserForUrl:(NSURL *)url
{
    id<SBChoosyUrlParser> parser;
    
    // TODO: Add more parsers
    if ([self isTwitterUrl:url]) {
        parser = [SBChoosyUrlParserTwitter new];
    } else if ([self isEmailUrl:url]) {
        parser = [SBChoosyUrlParserEmail new];
    }
    
    return parser;
}

+ (BOOL)isTwitterUrl:(NSURL *)url
{
    NSString *scheme = [[url scheme] lowercaseString];
    NSString *host = [[url host] lowercaseString];
    
    return [host isEqualToString:@"twitter.com"] || [scheme isEqualToString:@"twitter"];
}

+ (BOOL)isEmailUrl:(NSURL *)url
{
    return [[[url scheme] lowercaseString] isEqualToString:@"mailto"];
}

@end
