//
//  SBChoosyAppType+Protected.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 2/21/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyAppType.h"

@interface SBChoosyAppType (Protected)

- (void)checkForInstalledApps;
- (void)checkForNewlyInstalledAppsGivenLastDetectedAppKeys:(NSArray *)lastDetectedAppKeys;

@end
