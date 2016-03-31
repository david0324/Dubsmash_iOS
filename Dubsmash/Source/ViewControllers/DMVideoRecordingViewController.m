//
//  DMVideoRecordingViewController.m
//  Dubsmash
//
//  Created by Altair on 4/27/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import "DMVideoRecordingViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SoundManager.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "DMUtils.h"
#import "AppDelegate.h"

@interface DMVideoRecordingViewController ()
{
    AVAssetWriterInput *_wVideoInput;
    AVAssetWriterInput *_wAudioInput;
    
    CMTime lastSampleTime;
    BOOL bEncode;
    NSTimer *playingTimer;
    
    AudioBufferList *readBuffer;
    AppDelegate *appDelegate;

}
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoLayer;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, assign) AVCaptureDevicePosition cameraType;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, retain) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, retain) AVAssetWriter *writer;
@property (nonatomic, retain) AVAssetWriter *writerCodec;

@end

@implementation DMVideoRecordingViewController
@synthesize captureVideoLayer, cameraView, audioPlot, session, cameraType, recordBtn, videoOutput, audioOutput, cameraBtn, audioFile,eof, progressImageView, recordTitleLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cameraView.backgroundColor = [UIColor clearColor];
    self.navigationController.navigationBarHidden = YES;
    self.cameraType = AVCaptureDevicePositionFront;
    [self initAudioWaveView];
    [self initializeCamera];
    [self addVideoDataOutput];
    appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setProgress:0.0f];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    appDelegate.recordingVC = nil;
}
- (void)initAudioWaveView {
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    // Fill
    self.audioPlot.shouldFill      = YES;
    // Mirror
    self.audioPlot.shouldMirror    = YES;
    
    [progressImageView setFrame:CGRectMake(0, 0, 1.0f, audioPlot.frame.size.height)];
    NSString* filename = @"2.mp3";
    
    NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:filename ofType:nil]];
    [self openFileWithFilePathURL:url];
}

#pragma mark - Action Extensions
-(void)openFileWithFilePathURL:(NSURL*)filePathURL {
    
    self.audioFile          = [EZAudioFile audioFileWithURL:filePathURL];
    self.eof                = NO;
    
    // Plot the whole waveform
    self.audioPlot.plotType        = EZPlotTypeBuffer;
    self.audioPlot.shouldFill      = YES;
    self.audioPlot.shouldMirror    = YES;
    [self.audioFile getWaveformDataWithCompletionBlock:^(float *waveformData, UInt32 length) {
        [self.audioPlot updateBuffer:waveformData withBufferSize:length];
    }];
    
}


#pragma mark -Camera
- (void)initializeCamera {
    bEncode = NO;
    if (captureVideoLayer) {
        [captureVideoLayer removeFromSuperlayer];
        captureVideoLayer = nil;
    }
    session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    [self startCamera];
    [session commitConfiguration];
    [session startRunning];
}

- (void)startCamera
{
    AVCaptureDevice *device = [self CameraIfAvailable];
//    CGRect window = [cameraView bounds];
    if (device) {
        session.sessionPreset = AVCaptureSessionPresetHigh;
        
        NSError *error = nil;
        
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!input) {
        } else {
            if ([session canAddInput:input]) {
                [session addInput:input];
                
                captureVideoLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
                
                captureVideoLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width);
                captureVideoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                captureVideoLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
                
                [cameraView.layer insertSublayer:captureVideoLayer atIndex:0];
            } else {
            }
//            AVCaptureDevice *audioDevice= [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
//            AVCaptureDeviceInput *audioIn = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
//            [session addInput:audioIn];
            
        }
    } else {
    }
}

- (AVCaptureDevice *)CameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == self.cameraType) {
            captureDevice = device;
            break;
        }
    }
    
    //just in case
    if (!captureDevice) {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return captureDevice;
}

#pragma mark - Record Video
- (IBAction)onRecordAction:(id)sender {
    if([recordBtn isSelected]) {
        appDelegate.recordingVC = nil;
        [self stopAutoRecording];
    }else{
        appDelegate.recordingVC = self;
        [self startAutoRecording];
    }
}

- (void)stopAutoRecording {
    [self setProgress:0.0f];
    [[SoundManager sharedManager].currentMusic setCurrentTime:0];
    [[SoundManager sharedManager].currentMusic stop];
    [SoundManager sharedManager].currentMusic = nil;

    [recordTitleLabel setHidden:NO];
    [cameraBtn setHidden:NO];
    [recordBtn setSelected:NO];
    [self stopRecord];
    [playingTimer invalidate];
    playingTimer = nil;
}

- (void)startAutoRecording {
    [recordTitleLabel setHidden:YES];
    [cameraBtn setHidden:YES];
    [recordBtn setSelected:YES];
    [self recordVideo];
    [self startPlayWav];
}

- (void)updateTime:(NSTimer *)timer {
    if(![[SoundManager sharedManager].currentMusic isPlaying]) {
        [self stopAutoRecording];
        [self performSegueWithIdentifier:@"DMVideoPreviewIdentifier" sender:nil];
        return;
    }
    if ([SoundManager sharedManager].currentMusic.duration == 0.f) {
        return;
    }
    float fProgress = [SoundManager sharedManager].currentMusic.currentTime / [SoundManager sharedManager].currentMusic.duration;
    [self setProgress:fProgress];
}

- (void)setProgress:(float)progress {
    [progressImageView setFrame:CGRectMake(self.audioPlot.frame.size.width * progress, progressImageView.frame.origin.y, progressImageView.frame.size.width, progressImageView.frame.size.height)];
}

- (void)stopRecord {
    bEncode = NO;
    if(_writer) {
        [_writer finishWritingWithCompletionHandler:^{
            [self deleteWriter];
        }];
    }
    if(_writerCodec) {
        [_writerCodec finishWritingWithCompletionHandler:^{
            [self deleteWriterCodec];
        }];
    }

}

- (void)startPlayWav {

    /*
     Load in the sample file
     */
    
    [self setProgress:0.0f];
    NSString* filename = @"2.mp3";
    [[SoundManager sharedManager] playMusic:filename looping:NO];
    playingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
}

- (void) deleteWriter
{
    _wVideoInput = nil;
    _wAudioInput = nil;
    _writer = nil;
}

- (void) deleteWriterCodec
{
    _writerCodec = nil;
}


- (void)recordVideo {
    //    avcEncoder = [[AVCEncoder alloc] init];
    //    avcEncoder.maxBitrate = 0;
    [self createWriter];
    bEncode = YES;
}

- (void) createWriter
{
    CGSize winSize = cameraView.frame.size;
    // NSString *file = [self file];
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"capture.mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    
    NSError *error = nil;
    _writer = [[AVAssetWriter alloc] initWithURL:videoURL fileType:AVFileTypeQuickTimeMovie
                                           error:&error];
    NSDictionary *settings;
    
    
    settings = [NSDictionary dictionaryWithObjectsAndKeys:
                AVVideoCodecH264, AVVideoCodecKey,
                [NSNumber numberWithInt:winSize.width], AVVideoWidthKey,
                [NSNumber numberWithInt:winSize.height], AVVideoHeightKey,
                AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey,
                nil];
    
    _wVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings] ;
    
    [_wVideoInput setExpectsMediaDataInRealTime:YES];
    if(![_writer canAddInput:_wVideoInput])
    {
        return;
    }
    
    [_writer addInput:_wVideoInput];
}

- (void) addVideoDataOutput {
    videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    //TODO: This can cause sync issues if set to NO. Figure out why. Is it encoder backup????
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoOutput setVideoSettings:videoSettings];
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    if ([session canAddOutput:videoOutput])
        [session addOutput:videoOutput];
    else
        NSLog(@"Couldn't add video output");
}

#pragma mark -
#pragma mark Video Processing
#pragma mark -

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
    for ( AVCaptureConnection *connection in connections ) {
        
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:mediaType] ) {
                return connection;
            }
        }
    }
    return nil;
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    @autoreleasepool
    {
        if([connection isVideoOrientationSupported]) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
            connection.videoMirrored = YES;
            [connection setVideoOrientation:orientation];
        }
        //ONCAM_DEBUG("new value %lld old value %lld ", pts, (int64_t)(CMTimeGetSeconds( CMSampleBufferGetPresentationTimeStamp( sampleBuffer ) ) * 1000000) );
        if( !CMSampleBufferDataIsReady(sampleBuffer) )
        {
            return;
        }
        if(bEncode ) {
            lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            AVAssetWriterStatus awStatus = _writer.status;
            if( awStatus != AVAssetWriterStatusWriting )
            {
                [_writer startWriting];
                [_writer startSessionAtSourceTime:lastSampleTime];
            }
            else
            {
                if(captureOutput == videoOutput)
                    [self RecordingVideoWithBuffer:sampleBuffer];
            }
        }
    }
}

-(void) RecordingVideoWithBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (!_wVideoInput.readyForMoreMediaData && bEncode)
    {
        [self performSelector:@selector(RecordingVideoWithBuffer:) withObject:(__bridge id)(sampleBuffer) afterDelay:0.05];
        return;
    }
    
    @try {
        [_wVideoInput appendSampleBuffer:sampleBuffer];
    } @catch (NSException *ex) {
    }
}

- (void) RecordingAudioWithBuffer:(CMSampleBufferRef)sampleBuffer
{
}

- (IBAction)onCameraChangeAction:(id)sender {
    if(![cameraBtn isSelected]) {
        [cameraBtn setSelected:YES]; //back
        self.cameraType = AVCaptureDevicePositionBack;
    }else{
        [cameraBtn setSelected:NO]; //front
        self.cameraType = AVCaptureDevicePositionFront;
    }
    [self initializeCamera];
    [session removeOutput:videoOutput];
    videoOutput = nil;
    [self addVideoDataOutput];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND , 0), ^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self addVideoDataOutput];
//        });
//    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
