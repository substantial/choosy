//
//  ChoosyAppInfo+Protected.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/1/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyLocalStore.h"
#import "ChoosyAppInfo+Protected.h"
#import "ChoosyAppAction.h"

@implementation ChoosyAppInfo (Protected)

// TODO: updateWithReachability: ?
- (void)update
{
    // TODO: add cache expiration here even if app icon exists, github issue 8
    if (![ChoosyLocalStore appIconExistsForAppKey:self.appKey])
    {
        [self downloadAppIcon];
    }
}

- (void)mergeUpdatedData:(ChoosyAppInfo *)updatedAppInfo
{
    // merge actions
    NSMutableArray *objectsToAdd = [NSMutableArray new];
    for (ChoosyAppAction *updatedAction in updatedAppInfo.appActions)
    {
        ChoosyAppAction *existingAction = [self findActionWithKey:updatedAction.actionKey];
        if (existingAction) {
            existingAction = updatedAction;
        } else {
            [objectsToAdd addObject:updatedAction];
        }
    }
    self.appActions = [self.appActions arrayByAddingObjectsFromArray:objectsToAdd];
}

@end
