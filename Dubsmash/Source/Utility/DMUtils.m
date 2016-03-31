//
//  DMUtils.m
//  Dubsmash
//
//  Created by Altair on 4/30/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import "DMUtils.h"

@implementation DMUtils
static DMUtils *_sharedUtil = nil;

+ (DMUtils *)sharedUtils
{
    if(_sharedUtil == nil) {
        _sharedUtil = [[DMUtils alloc] init];
        _sharedUtil.videoTitle = @"";
    }
    return _sharedUtil;
    
}

@end
