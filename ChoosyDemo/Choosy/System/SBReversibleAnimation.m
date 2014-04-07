//
//  SBReversibleAnimation.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 4/2/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBReversibleAnimation.h"

@interface SBReversibleAnimation ()

@property (nonatomic) BOOL reversed;
@property (nonatomic) NSString *name;
@property (nonatomic) CFTimeInterval lastAnimationStartTime; // media time of last animation (zero the first time)

@end

@implementation SBReversibleAnimation

- (void)start
{
    self.fromValue = [self.layer.presentationLayer valueForKeyPath:self.keyPath];
    self.toValue = self.endValue;
    
    [UIView animateWithDuration:self.duration animations:^{
        [self.layer setValue:self.toValue forKeyPath:self.keyPath];
         self.lastAnimationStartTime = CACurrentMediaTime();
    } completion:^(BOOL finished) {
        if (finished && self.animationCompletionBlock) {
            self.animationCompletionBlock();
        }
    }];
    
    [self.layer setValue:self.toValue forKeyPath:self.keyPath];
}

- (void)reverse
{
    CFTimeInterval duration;
    CFTimeInterval currentMediaTime = CACurrentMediaTime();
    
    // if we previously animated, then calculate how far along in the previous animation we were
    // and we'll use that for the duration of the reversing animation; if larger than
    // self.duration that means the prior animation was done, so we'll just use
    // self.duration for the length of this animation
    if (self.lastAnimationStartTime)
        duration = MIN(self.duration, (currentMediaTime - self.lastAnimationStartTime));
    
    // save our media time for future reference (i.e. future invocations of this routine)
    self.lastAnimationStartTime = currentMediaTime;
    
    if (duration < self.duration)
        self.lastAnimationStartTime -= (self.duration - duration);
    
    // grab the state of the layer as it appears to user right now
    CALayer *currentLayer = self.layer.presentationLayer;
    
    // cancel the animation in progress
    [self.layer removeAnimationForKey:self.keyPath];
    
    // set the actual property value to be whatever it was animated to before the animation stopped
    id currentValue = [currentLayer valueForKeyPath:self.keyPath];
    [self.layer setValue:currentValue forKeyPath:self.keyPath];
    
    self.reversed = !self.reversed;
    
    id newFinalValue;
    if (self.reversed)
        newFinalValue = self.startValue;
    else
        newFinalValue = self.endValue;
    
    // animate to new setting
    self.fromValue = currentValue;
    self.toValue = newFinalValue;
    self.duration = duration;
    
    [self.layer addAnimation:self forKey:self.keyPath];
    
    [self.layer setValue:newFinalValue forKeyPath:self.keyPath];
}

@end
