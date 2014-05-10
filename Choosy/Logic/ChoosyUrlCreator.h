//
//  ChoosyUrlCreator.h
//  Pods
//
//  Created by Sasha Novosad on 5/9/14.
//
//

#import <Foundation/Foundation.h>

@class ChoosyActionContext, ChoosyAppInfo, ChoosyAppType, ChoosyAppAction;

@interface ChoosyUrlCreator : NSObject

+ (NSURL *)urlForAction:(ChoosyActionContext *)actionContext targetingApp:(ChoosyAppInfo *)appInfo inAppType:(ChoosyAppType *)appType;
+ (NSURL *)urlForAction:(ChoosyAppAction *)action withActionParams:(NSDictionary *)actionParams appTypeParams:(NSArray *)appTypeParams;

@end
