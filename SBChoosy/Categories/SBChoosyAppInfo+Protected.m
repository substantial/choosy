//
//  SBChoosyAppInfo+Protected.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/1/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "SBChoosyLocalStore.h"
#import "SBChoosyAppInfo+Protected.h"

@implementation SBChoosyAppInfo (Protected)

- (void)update
{
    // TODO: add cache expiration here even if app icon exists
    
    if (![SBChoosyLocalStore appIconExistsForAppKey:self.appKey] && !self.isAppIconDownloading)
    {
        [self downloadAppIcon];
    }
}

@end
