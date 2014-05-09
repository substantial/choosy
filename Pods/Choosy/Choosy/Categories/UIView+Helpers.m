//
//  UIView+Helpers.m
//  Progress
//
//  Created by Alex Novosad on 12/6/13.
//  Copyright (c) 2013 Peg. All rights reserved.
//

#import "UIView+Helpers.h"

@implementation UIView (Helpers)

- (CGFloat)height
{
	return self.bounds.size.height;
}

- (CGFloat)width
{
	return self.bounds.size.width;
}

- (CGFloat)halfHeight
{
	return self.bounds.size.height / 2.0f;
}

- (CGFloat)halfWidth
{
	return self.bounds.size.width / 2.0f;
}

- (CGFloat)fheight
{
	return self.frame.size.height;
}

- (CGFloat)fwidth
{
	return self.frame.size.width;
}

- (CGFloat)bx
{
	return self.bounds.origin.x;
}

- (CGFloat)by
{
	return self.bounds.origin.y;
}

- (CGFloat)fx
{
	return self.frame.origin.x;
}

- (CGFloat)fy
{
	return self.frame.origin.y;
}

- (CGFloat)bottomY
{
	return self.fy + self.height;
}

- (CGFloat)rightX
{
	return self.fx + self.width;
}

- (void)setFx:(CGFloat)newX
{
    CGRect frame = self.frame;
    frame.origin.x = newX;
    self.frame = frame;
}

- (void)setFy:(CGFloat)newY
{
    CGRect frame = self.frame;
    frame.origin.y = newY;
    self.frame = frame;
}

- (void)setFHeight:(CGFloat)newHeight
{
    CGRect frame = self.frame;
    frame.size.height = newHeight;
    self.frame = frame;
}

- (void)setFWidth:(CGFloat)newWidth
{
    CGRect frame = self.frame;
    frame.size.width = newWidth;
    self.frame = frame;
}

@end
