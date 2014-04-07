//
//  SBChoosyAppType+Protected.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 2/21/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyAppType+Protected.h"
#import "NSArray+ObjectiveSugar.h"
#import "SBChoosyAppInfo.h"

@implementation SBChoosyAppType (Protected)

- (void)checkForInstalledApps
{
    for (SBChoosyAppInfo *app in self.apps) {
        app.isInstalled = [[UIApplication sharedApplication] canOpenURL:app.appURLScheme];;
    }
}

- (void)checkForNewlyInstalledAppsGivenLastDetectedAppKeys:(NSArray *)lastDetectedAppKeys
{
    [self.installedApps each:^(id object) {
        SBChoosyAppInfo *app = ((SBChoosyAppInfo *)object);
        app.isNew = ![lastDetectedAppKeys containsObject:app.appKey];
    }];
}

//- (NSArray *)newlyAddedApps
//{
//    return [self.apps select:^BOOL(id object) {
//        return ((SBChoosyAppInfo *)object).isNew;
//    }];
//}

@end
