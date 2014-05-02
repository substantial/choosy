//
//  SBChoosyUrlParserFactory.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBChoosyUrlParser.h"

@interface SBChoosyUrlParserFactory : NSObject

+ (id<SBChoosyUrlParser>)parserForUrl:(NSURL *)url;

@end
