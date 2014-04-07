//
//  SBReversibleAnimation.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 4/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface SBReversibleAnimation : CABasicAnimation

@property (nonatomic, weak) CALayer *layer;
@property (nonatomic) id startValue;
@property (nonatomic) id endValue;
@property (nonatomic, copy) void (^animationCompletionBlock)();

@property (nonatomic, readonly) BOOL reversed;
@property (nonatomic, readonly) NSString *name;

- (void)start;
- (void)reverse;

@end
