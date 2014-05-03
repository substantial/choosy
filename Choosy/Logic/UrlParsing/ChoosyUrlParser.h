//
//  ChoosyUrlParser.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChoosyActionContext.h"

@protocol ChoosyUrlParser <NSObject>

- (ChoosyActionContext *)parseUrl:(NSURL *)url;

@end
