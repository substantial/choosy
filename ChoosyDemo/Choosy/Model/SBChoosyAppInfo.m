//
//  SBChoosyAppInfo.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 2/3/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyAppInfo.h"

@implementation SBChoosyAppInfo

- (instancetype)initWithName:(NSString *)name key:(NSString *)key type:(NSString *)type actions:(NSArray *)actions
{
    if (self = [super init]) {
        _appName = name;
        _appKey = key;
        _appType = type;
        _appActions = actions;
    }
    return self;
}

@end
