//
//  ChoosyUrlParserFactory.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyUrlParserFactory.h"
#import "ChoosyUrlParserTwitter.h"
#import "ChoosyUrlParserEmail.h"
//#import "ChoosyUrlParserWeb.h"
//#import "ChoosyUrlParserMaps.h"

@implementation ChoosyUrlParserFactory

+ (id<ChoosyUrlParser>)parserForUrl:(NSURL *)url
{
    id<ChoosyUrlParser> parser;
    
    // TODO: Add more parsers
    if ([self isTwitterUrl:url]) {
        parser = [ChoosyUrlParserTwitter new];
    } else if ([self isEmailUrl:url]) {
        parser = [ChoosyUrlParserEmail new];
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
