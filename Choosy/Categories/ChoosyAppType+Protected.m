//
//  ChoosyAppType+Protected.m
//  Choosy
//
//  Created by Sasha Novosad on 2/21/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyGlobals.h"
#import "ChoosyAppType+Protected.h"
#import "ChoosyAppInfo.h"
#import "ChoosyAppInfo+Protected.h"
#import "ChoosyLocalStore.h"
#import "ChoosyAppTypeParameter.h"
#import "ChoosyAppTypeAction.h"

@implementation ChoosyAppType (Protected)

- (void)takeStockOfApps
{
    // do not offload this to another thread
    
    // TODO: cache last detected app keys in a local class-level array until the list changes
    // to reduce file reads
    NSArray *lastDetectedAppKeys = [ChoosyLocalStore lastDetectedAppKeysForAppTypeWithKey:self.key];
    
    for (ChoosyAppInfo *app in self.apps) {
        app.isInstalled = [[UIApplication sharedApplication] canOpenURL:app.appURLScheme];
        app.isNew = ![lastDetectedAppKeys containsObject:app.appKey];
        if (app.isInstalled) {
            [app update];
        }
    }
}

- (BOOL)needsUpdate
{
    if (!self.dateUpdated) return YES;
    
    NSInteger cacheAgeInHours = [[NSDate date] timeIntervalSinceDate:self.dateUpdated];
    BOOL timeToRefresh = CHOOSY_DEVELOPMENT_MODE == 1 || cacheAgeInHours > CHOOSY_CACHE_EXPIRATION_PERIOD;
    
    return timeToRefresh;
}

- (void)mergeUpdatedData:(ChoosyAppType *)updatedAppType
{
    // merge parameters
    NSMutableArray *objectsToAdd = [NSMutableArray new];
    for (ChoosyAppTypeParameter *updatedParam in updatedAppType.parameters)
    {
        ChoosyAppTypeParameter *existingParam = [self findParameterWithKey:updatedParam.key];
        if (existingParam) {
            existingParam = updatedParam;
        } else {
            [objectsToAdd addObject:updatedParam];
        }
    }
    self.parameters = [self.parameters arrayByAddingObjectsFromArray:objectsToAdd];
    [objectsToAdd removeAllObjects];
    
    // merge actions
    for (ChoosyAppTypeAction *updatedAction in updatedAppType.actions)
    {
        ChoosyAppTypeAction *existingAction = [self findActionWithKey:updatedAction.key];
        if (existingAction) {
            existingAction = updatedAction;
        } else {
            [objectsToAdd addObject:updatedAction];
        }
    }
    self.actions = [self.actions arrayByAddingObjectsFromArray:objectsToAdd];
    [objectsToAdd removeAllObjects];
    
    // merge apps
    for (ChoosyAppInfo *updatedAppInfo in updatedAppType.apps)
    {
        ChoosyAppInfo *existingApp = [self findAppInfoWithAppKey:updatedAppInfo.appKey];
        if (existingApp) {
            [existingApp mergeUpdatedData:updatedAppInfo];
        } else {
            [objectsToAdd addObject:updatedAppInfo];
        }
    }
    self.apps = [self.apps arrayByAddingObjectsFromArray:objectsToAdd];
}

- (ChoosyAppTypeParameter *)findParameterWithKey:(NSString *)key
{
    NSString *lowercaseKey = [key lowercaseString];
    for (ChoosyAppTypeParameter *param in self.parameters) {
        if ([param.key isEqualToString:lowercaseKey]) {
            return param;
        }
    }
    return nil;
}

- (ChoosyAppTypeAction *)findActionWithKey:(NSString *)key
{
    NSString *lowercaseKey = [key lowercaseString];
    for (ChoosyAppTypeAction *action in self.actions) {
        if ([action.key isEqualToString:lowercaseKey]) {
            return action;
        }
    }
    return nil;
}

@end
