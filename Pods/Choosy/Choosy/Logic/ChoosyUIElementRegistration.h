//
//  ChoosyUIElementRegistration.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 3/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  ChoosyActionContext;

@interface ChoosyUIElementRegistration : NSObject

@property (nonatomic) id uiElement;
@property (nonatomic) UITapGestureRecognizer *selectAppRecognizer;
@property (nonatomic) UILongPressGestureRecognizer *resetAppSelectionRecognizer;
@property (nonatomic) ChoosyActionContext *actionContext;

@end
