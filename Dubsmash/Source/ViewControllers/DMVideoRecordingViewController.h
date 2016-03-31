//
//  DMVideoRecordingViewController.h
//  Dubsmash
//
//  Created by Altair on 4/27/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FVSoundWaveView.h"
#import "EZAudio.h"

@interface DMVideoRecordingViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    
}
/**
 The EZAudioFile representing of the currently selected audio file
 */
@property (nonatomic,strong) EZAudioFile *audioFile;
/**
 A BOOL indicating whether or not we've reached the end of the file
 */
@property (nonatomic,assign) BOOL eof;

@property (nonatomic, retain) IBOutlet EZAudioPlot *audioPlot;
@property (nonatomic, retain) IBOutlet UIImageView *progressImageView;
@property (nonatomic, retain) IBOutlet UIView *cameraView;
@property (nonatomic, retain) IBOutlet UIButton *recordBtn;
@property (nonatomic, retain) IBOutlet UIButton *cameraBtn;
@property (nonatomic, retain) IBOutlet UILabel *recordTitleLabel;

- (void)stopAutoRecording;
@end
