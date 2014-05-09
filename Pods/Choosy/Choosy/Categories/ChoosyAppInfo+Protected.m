//
//  ChoosyAppInfo+Protected.m
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/1/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import "ChoosyLocalStore.h"
#import "ChoosyAppInfo+Protected.h"

@implementation ChoosyAppInfo (Protected)

- (void)update
{
    // TODO: add cache expiration here even if app icon exists
    
    if (![ChoosyLocalStore appIconExistsForAppKey:self.appKey] && !self.isAppIconDownloading)
    {
        [self downloadAppIcon];
    }
}

@end
