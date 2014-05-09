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

//- (NSArray *)newlyAddedApps
//{
//    return [self.apps select:^BOOL(id object) {
//        return ((ChoosyAppInfo *)object).isNew;
//    }];
//}

@end
