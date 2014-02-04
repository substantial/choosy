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

@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *uniqueName;
@property (nonatomic, readonly) SBChoosyAppType *type;
@property (nonatomic, readonly) NSArray *supportedActions; // of SBChoosyAppAction

@end
