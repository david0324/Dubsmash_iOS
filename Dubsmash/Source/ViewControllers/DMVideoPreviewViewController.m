//
//  DMVideoPreviewViewController.m
//  Dubsmash
//
//  Created by Altair on 4/28/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import "DMVideoPreviewViewController.h"
#import "AVFoundation/AVFoundation.h"
#import "SoundManager.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "DMUtils.h"
#import <CoreText/CoreText.h>
#import "AppDelegate.h"
@interface DMVideoPreviewViewController ()
{
    AVPlayer *player;
    BOOL isMute;
    float musicVolume;
    AVPlayerLayer *videoPlayingLayer;
    AppDelegate *appDelegate;
}
@end

@implementation DMVideoPreviewViewController
@synthesize videoPlayingView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    isMute = NO;
    [[self.titleTxt valueForKey:@"textInputTraits"] setValue:[UIColor clearColor] forKey:@"insertionPointColor"];
    appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.titleTxt setText:[DMUtils sharedUtils].videoTitle];
    self.titleTxt.autocorrectionType = UITextAutocorrectionTypeNo;
    [[UITextField appearance] setTintColor:[UIColor blueColor]];
    [self.titleTxt becomeFirstResponder];
    [self.titleTxtView setFrame:CGRectMake(0, self.titleTxtView.frame.origin.y, self.view.frame.size.width, self.titleTxtView.frame.size.height)];
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"capture.mp4"];
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    player = [AVPlayer playerWithURL:videoURL];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    
    videoPlayingLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    
    [videoPlayingLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width *  videoPlayingView.frame.size.height / videoPlayingView.frame.size.width)];
    [videoPlayingLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    [videoPlayingView.layer insertSublayer:videoPlayingLayer atIndex:0];
    [player play];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSString* filename = @"2.mp3";
    [[SoundManager sharedManager] playMusic:filename looping:NO];
    if([SoundManager sharedManager].musicVolume  > 0)
        musicVolume = [SoundManager sharedManager].musicVolume;
    appDelegate.previewVC = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
    appDelegate.previewVC = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) playMedia {
    [player play];
    NSString* filename = @"2.mp3";
    [[SoundManager sharedManager] playMusic:filename looping:NO];
}

- (void) stopMedia {
    [player pause];
    [[SoundManager sharedManager] stopMusic];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
    NSString* filename = @"2.mp3";
    if([[SoundManager sharedManager] isPlayingMusic]) {
        [[SoundManager sharedManager] stopMusic:YES];
    }
    [[SoundManager sharedManager] playMusic:filename looping:NO];
}

- (void)mergeAudioVideo {
    
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = self.titleMark.text;
    titleLayer.font = (__bridge CFTypeRef)(@"Helvetica");
    titleLayer.fontSize = 15;
    //?? titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    CGRect TR1 = [self dimensionsForTextLayer: titleLayer];
    titleLayer.anchorPoint = CGPointMake(0, -TR1.origin.y/TR1.size.height);    // left side of baseline
    titleLayer.bounds = TR1;
    

    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"final_video.mp4"];
    if ([[NSFileManager defaultManager]fileExistsAtPath:outputFilePath])
        [[NSFileManager defaultManager]removeItemAtPath:outputFilePath error:nil];
    
    NSURL    *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    
    NSString* videoOutputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"capture.mp4"];

    NSString* audioOutputPath = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"mp3"];;

    NSURL *video_inputFileUrl = [NSURL fileURLWithPath:videoOutputPath];
    NSURL *audio_inputFileUrl = [NSURL fileURLWithPath:audioOutputPath isDirectory:YES];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:options];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CMTime videoDuration = videoAssetTrack.timeRange.duration;
    
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,videoDuration);
    CGSize videoSize = [[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    titleLayer.frame = CGRectMake(videoSize.width / 2, self.titleMark.frame.size.height / 2, videoSize.width / 2, self.titleMark.frame.size.height);
    [parentLayer addSublayer:videoLayer];
    if(![self.titleTxt.text isEqualToString:@""]) {
        CATextLayer *titleTextLayer = [CATextLayer layer];
        titleTextLayer.string = self.titleTxt.text;
        titleTextLayer.font = (__bridge CFTypeRef)(@"Helvetica");
        titleTextLayer.fontSize = 15;
        titleTextLayer.backgroundColor = [UIColor colorWithRed:(85.f / 255.f) green:(85.f / 255.f) blue:(85.f / 255.f) alpha:0.7].CGColor;
        //?? titleLayer.shadowOpacity = 0.5;
        titleTextLayer.alignmentMode = kCAAlignmentCenter;
        CGRect TR = [self dimensionsForTextLayer: titleTextLayer];
        titleTextLayer.anchorPoint = CGPointMake(0, -TR.origin.y/TR.size.height);    // left side of baseline
        titleTextLayer.bounds = TR;
        titleTextLayer.frame = CGRectMake(0, videoSize.height - self.titleTxtView.frame.origin.y - self.titleTxtView.frame.size.height, self.titleTxtView.frame.size.width, self.titleTxtView.frame.size.height);
        [parentLayer addSublayer:titleTextLayer];
    }
    [parentLayer addSublayer:titleLayer];
    
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
    
    AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];

    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, (int)videoAsset.duration.value);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];

    
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    _assetExport.videoComposition = videoComp;
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = outputFileUrl;
    CMTime start = CMTimeMakeWithSeconds(1, 600);
    
    float deltaValue = videoDuration.value / 600.f;
    CMTime duration = CMTimeMakeWithSeconds(deltaValue - 1, 600);
    
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    _assetExport.timeRange = range;
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
         dispatch_async(dispatch_get_main_queue(), ^{
         [MBProgressHUD hideHUDForView:self.view animated:YES];
         if (_assetExport.status == AVAssetExportSessionStatusCompleted) {
             [videoPlayingLayer removeFromSuperlayer];
             [self performSegueWithIdentifier:@"DMVideoShareIdentifier" sender:nil];
             //Write Code Here to Continue
         }
         else {
             //Write Fail Code here
         }
         });
        }
     ];
}
- (IBAction)onBackAction:(id)sender {
    [self.titleTxt setHidden:YES];
    [SoundManager sharedManager].musicVolume = musicVolume;
    [DMUtils sharedUtils].videoTitle = @"";
    [self.titleTxt resignFirstResponder];
    [player pause];
    [[SoundManager sharedManager] stopMusic];
    [SoundManager sharedManager].musicVolume = musicVolume;
    [videoPlayingLayer removeFromSuperlayer];
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)onMuteAction:(id)sender {
    if([self.muteButton isSelected]) { //No Mute
        isMute = NO;
        [SoundManager sharedManager].musicVolume = musicVolume;
        [self.muteButton setSelected:NO];
    }else{
        isMute = YES;
        musicVolume = [SoundManager sharedManager].musicVolume;
        [SoundManager sharedManager].musicVolume = 0.0f;
        [self.muteButton setSelected:YES];
    }
}

- (IBAction)onSaveAction:(id)sender {
    if([self.titleTxt.text isEqualToString:@""]) {
        [self.titleTxt setHidden:YES];
    }else{
        [self.titleTxt setHidden:NO];
    }
    [DMUtils sharedUtils].videoTitle = self.titleTxt.text;
    [self.titleTxt resignFirstResponder];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.detailsLabelText = @"Your video is being \n created. Please wait a \n few seconds.";
    [player pause];
    [[SoundManager sharedManager] stopMusic];
    [self mergeAudioVideo];
}

#pragma mark -UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.titleTxt resignFirstResponder];
    [DMUtils sharedUtils].videoTitle = textField.text;
    [self onSaveAction:nil];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.returnKeyType = UIReturnKeyNext;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if([string isEqualToString:@""] && [textField.text length] == 1) {
        [self.titleTxt setHidden:YES];
        [self.titleTxtView setBackgroundColor:[UIColor clearColor]];
        return YES;
    }else{
        [self.titleTxt setHidden:NO];
        [self.titleTxtView setBackgroundColor:[UIColor darkGrayColor]];
        // Combine the new text with the old
        NSString *combinedText = [textField.text stringByReplacingCharactersInRange:range withString:[NSString stringWithFormat:@"%@", string]];
        
        // See if the width of the combined text + the text field's
        // left layout margin + the text field's right layout margin
        // is greater than or equal to the width of the textField
        // (I've multiplied the right margin by 2 to prevent the cursor
        // from shifting the field one extra character when the text field
        // if full)
        CGFloat textWidth =  [combinedText sizeWithAttributes:@{NSFontAttributeName: textField.font}].width + textField.layoutMargins.left + textField.layoutMargins.right * 2;
        CGFloat textFieldWidth = self.view.frame.size.width * 0.9;
        
        // If the text + margins is as wide or wider than the text field
        // don't add the new character, i.e. return NO. Else add the
        // character by returning YES.
        if (textWidth >= textFieldWidth) {
            return NO;
        } else {
            [self.titleTxt setFrame:CGRectMake((self.view.frame.size.width - textWidth) / 2, (self.titleTxtView.frame.size.height - self.titleTxt.frame.size.height) / 2, textWidth, self.titleTxt.frame.size.height)];
            return YES;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:self.videoPlayingView];
    if(location.y > (self.videoPlayingView.frame.size.height - self.titleTxtView.frame.size.height / 2) || location.y < self.titleTxtView.frame.size.height / 2)
        return;
    [self.titleTxtView setCenter:CGPointMake(self.titleTxtView.center.x, location.y)];
}


// Use this if you are already storing your data as attributed strings.
-(CGRect) dimensionsForAttributedString: (NSAttributedString *) asp {
    CGFloat ascent = 0, descent = 0, width = 0;
    CTLineRef line = CTLineCreateWithAttributedString( (CFAttributedStringRef) asp);
    width = CTLineGetTypographicBounds( line, &ascent, &descent, NULL );
    CFRelease(line);
    width = ceilf(width);                   // Force width to integral.
    if (((int)width)%2) width += 1.0;       // Force width to even.
    return CGRectMake(0, -descent, width, ceilf(ascent+descent));
}

/*      Obsolete version:
 
 -(CGRect) dimensionsForAttributedString: (NSAttributedString *) asp {
 CGFloat ascent = 0, descent = 0, width = 0;
 CTLineRef line = CTLineCreateWithAttributedString( (CFAttributedStringRef) asp);
 width = CTLineGetTypographicBounds( line, &ascent, &descent, NULL );
 CFRelease(line);
 return CGRectMake(0, -descent, width, ascent+descent);
 }
 */

// Use this if you are using plain strings and you need to calculate a new size for a change you are about to make.
-(CGRect) dimensionsForString: (NSString *) s font: (NSString *) fontName size: (CGFloat) fontSize {
    UIFont *font = [UIFont fontWithName: fontName size: fontSize];
    NSDictionary *attribs = [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName];
    NSAttributedString *asp = [[NSAttributedString alloc] initWithString: s attributes: attribs];
    CGRect R = [self dimensionsForAttributedString: asp];
    return R;
}

// Use this to calculate dimensions for a text layer that already exists.
-(CGRect) dimensionsForTextLayer: (CATextLayer *) layer {
    CFStringRef fontName = (__bridge CFTypeRef)(@"Helvetica");
    return [self dimensionsForString: layer.string font: (__bridge NSString *) fontName size: layer.fontSize];
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
