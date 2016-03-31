//
//  DMUtils.h
//  Dubsmash
//
//  Created by Altair on 4/30/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMUtils : NSObject
{
    
}
+ (DMUtils *)sharedUtils;

@property (nonatomic, retain) NSString *videoTitle;
@end
