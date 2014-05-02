//
//  SBChoosyUrlParser.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBChoosyActionContext.h"

@protocol SBChoosyUrlParser <NSObject>

- (SBChoosyActionContext *)parseUrl:(NSURL *)url;

@end
