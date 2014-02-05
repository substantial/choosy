//
//  SBChoosyAppInfo.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 2/3/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SBChoosyAppType;

@interface SBChoosyAppInfo : NSObject

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appKey;
@property (nonatomic, readonly) SBChoosyAppType *appType;
@property (nonatomic, readonly) NSArray *appActions; // of SBChoosyAppAction

@end
