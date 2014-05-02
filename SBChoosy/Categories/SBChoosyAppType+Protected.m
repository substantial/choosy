//
//  SBChoosyAppType+Protected.m
//  Choosy
//
//  Created by Sasha Novosad on 2/21/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyGlobals.h"
#import "SBChoosyAppType+Protected.h"
#import "SBChoosyAppInfo.h"
#import "SBChoosyAppInfo+Protected.h"
#import "SBChoosyLocalStore.h"

@implementation SBChoosyAppType (Protected)

- (void)takeStockOfApps
{
    // do not offload this to another thread
    
    // TODO: cache last detected app keys in a local class-level array until the list changes
    // to reduce file reads
    NSArray *lastDetectedAppKeys = [SBChoosyLocalStore lastDetectedAppKeysForAppTypeWithKey:self.key];
    
    for (SBChoosyAppInfo *app in self.apps) {
        if ([[UIApplication sharedApplication] canOpenURL:app.appURLScheme]) {
            app.isInstalled = YES;
            app.isNew = ![lastDetectedAppKeys containsObject:app.appKey];
            [app update];
        }
    }
}

- (BOOL)needsUpdate
{
    if (!self.dateUpdated) return YES;
    
    NSInteger cacheAgeInHours = [[NSDate date] timeIntervalSinceDate:self.dateUpdated];
    BOOL timeToRefresh = SBCHOOSY_DEVELOPMENT_MODE == 1 || cacheAgeInHours > SBCHOOSY_CACHE_EXPIRATION_PERIOD;
    
    return timeToRefresh;
}

//- (NSArray *)newlyAddedApps
//{
//    return [self.apps select:^BOOL(id object) {
//        return ((SBChoosyAppInfo *)object).isNew;
//    }];
//}

@end
