
#import "UIView+Screenshot.h"

@implementation UIView (Screenshot)

- (UIImage *)screenshot
{
	UIGraphicsBeginImageContext(self.bounds.size);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *screenie = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return screenie;
}

- (UIImage *)screenshotOfRect:(CGRect)rect
{
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(ctx, -rect.origin.x, -rect.origin.y);
    
    [self.layer renderInContext:ctx];
    
    UIImage *screenie = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return screenie;
}

@end
