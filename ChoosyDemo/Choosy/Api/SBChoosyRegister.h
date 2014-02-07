/*
 * Create an instance of this on every view controller that has UI elements 
 * that you want to register with Choosy.
 */

#import <Foundation/Foundation.h>

@class SBChoosyActionContext;

@interface SBChoosyRegister : NSObject

- (void)registerUIElement:(id)uiElement forAction:(SBChoosyActionContext *)actionContext;

@end
