//
//  SBChoosyUIElementRegistration.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 3/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  SBChoosyActionContext;

@interface SBChoosyUIElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) SBChoosyActionContext *actionContext;

@end
