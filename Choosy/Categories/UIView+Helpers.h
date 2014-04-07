//
//  UIView+Helpers.h
//  Progress
//
//  Created by Alex Novosad on 12/6/13.
//  Copyright (c) 2013 Peg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Helpers)

- (CGFloat)height; // height, bounds
- (CGFloat)width; // width, bounds
- (CGFloat)halfHeight; // height / 2.0f
- (CGFloat)halfWidth; // width / 2.0f
- (CGFloat)fheight; // height, frame
- (CGFloat)fwidth; // width, frame
- (CGFloat)bx; // bounds x
- (CGFloat)by; // bounds y
- (CGFloat)fx; // frame x
- (CGFloat)fy; // frame y
- (CGFloat)bottomY; // fy + height
- (CGFloat)rightX; // fx + width

- (void)setFx:(CGFloat)newX;
- (void)setFy:(CGFloat)newY;
- (void)setFHeight:(CGFloat)newHeight;
- (void)setFWidth:(CGFloat)newWidth;

@end
