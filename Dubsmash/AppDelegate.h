//
//  AppDelegate.h
//  Dubsmash
//
//  Created by Altair on 4/27/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DMVideoRecordingViewController.h"
#import "DMVideoPreviewViewController.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) DMVideoRecordingViewController *recordingVC;
@property (nonatomic, retain) DMVideoPreviewViewController *previewVC;
@end

