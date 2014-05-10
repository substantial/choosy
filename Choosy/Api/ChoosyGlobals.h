//
//  ChoosyGlobals.h
//  ChoosyDemo
//
//  Created by Sasha Novosad on 5/1/14.
//  Copyright (c) 2014 Substantial. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CHOOSY_DEVELOPMENT_MODE 1
#define CHOOSY_ALWAYS_DISPLAY_PICKER 0
#define CHOOSY_CACHE_EXPIRATION_PERIOD 24 * 3600 // 24 hours, when dev mode is 0

@interface ChoosyGlobals : NSObject

@end
