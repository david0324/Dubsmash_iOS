//
//  DMVideoShareViewController.m
//  Dubsmash
//
//  Created by Altair on 4/29/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import "DMVideoShareViewController.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <SCFacebook/SCFacebook.h>
#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>
@interface DMVideoShareViewController ()
{
    NSString *outputFilePath;
    UIDocumentInteractionController *docController;
}
@end
#define INSTAGRAM_CLIENT_ID         @"4ecd49a784244ff9b135c37245bc5df0"
#define INSTAGRAM_CLIENT_SECRET     @"2f485677ad0b46c29264ed14abf313c6"
#define ALERT_MESSENGER_TAG         100
@implementation DMVideoShareViewController
@synthesize mWebView;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"final_video.mp4"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onMessengerAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share with Facebook Messenger" message:@"Your Dub is now in the Camera Roll and can be imported by Facebook Messenger" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    alertView.tag = ALERT_MESSENGER_TAG;
    [alertView show];
}
- (IBAction)onWhatsappAction:(id)sender {
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"]) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
        }else{
        }
    }else{
    }
    NSURL *filePathURL = [NSURL fileURLWithPath:outputFilePath isDirectory:NO];
    docController = [UIDocumentInteractionController interactionControllerWithURL:filePathURL];
    docController.delegate = self;
    [docController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];

}
- (IBAction)onMessageAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString *deviceType = [UIDevice currentDevice].model;
    if([deviceType isEqualToString:@"iPhone"]) {
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]]) {
            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
            messageController.messageComposeDelegate = self;
            if([MFMessageComposeViewController canSendText]) {
                NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outputFilePath]];
                BOOL didAttachVideo = [messageController addAttachmentData:videoData typeIdentifier:@"public.movie" filename:outputFilePath];
                
                if (didAttachVideo) {
                    NSLog(@"Video Attached.");
                    
                } else {
                    NSLog(@"Video Could Not Be Attached.");
                }
            }
            [self presentViewController:messageController animated:YES completion:nil];

        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Send Message" message:@"Text messaging is not available without SIM." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }else{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cannot Send Message" message:@"Text messaging is not available on iPad." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alertView show];
    }

    [self performSelector:@selector(hideIndicator) withObject:nil afterDelay:3.0f];
}

//MFMessageComposeViewController Delegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled:
        {
            NSLog(@"Cancelled");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancelled Sending Video" message:@"You're cancelled sending video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
            break;
        case MessageComposeResultFailed:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed!" message:@"You can't send video" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
            break;
        case MessageComposeResultSent:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"The video file has sent." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
            break;
        default:
            break;
    }
}

- (IBAction)onCameraRollAction:(id)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSURL *video_outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
    [self saveToCameraRoll:video_outputFileUrl];
}

- (IBAction)onFacebookAction:(id)sender {
    //Login Part
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [SCFacebook loginCallBack:^(BOOL success, id result) {
        if(success){
            NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outputFilePath]];
            [SCFacebook feedPostWithVideo:videoData title:@"" description:@"" callBack:^(BOOL success, id result) {
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                if(success) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"The video uploading was successed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }else{
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Failed!" message:@"The video uploading was failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alertView show];
                }
            }];
        }else{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }];
}
- (IBAction)onInstagramAction:(id)sender {
    // webview
    [mWebView setHidden:NO];
    mWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    mWebView.scrollView.bounces = NO;
    mWebView.contentMode = UIViewContentModeScaleAspectFit;
    mWebView.delegate = self;

    NSDictionary *configuration = [InstagramEngine sharedEngineConfiguration];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=token", configuration[kInstagramKitAuthorizationUrlConfigurationKey], configuration[kInstagramKitAppClientIdConfigurationKey], configuration[kInstagramKitAppRedirectUrlConfigurationKey]]];
    
    [mWebView loadRequest:[NSURLRequest requestWithURL:url]];
//
//    [[InstagramEngine sharedEngine] loginWithBlock:^(NSError *error) {
//        NSLog(error);
//    }];
//    [self performSelector:@selector(hideIndicator) withObject:nil afterDelay:3.0f];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *URLString = [request.URL absoluteString];
    NSLog(@"Redirect_URI %@", [[InstagramEngine sharedEngine] appRedirectURL]);
    if ([URLString hasPrefix:[[InstagramEngine sharedEngine] appRedirectURL]]) {
        NSString *delimiter = @"access_token=";
        NSArray *components = [URLString componentsSeparatedByString:delimiter];
        if (components.count > 1) {
            NSString *accessToken = [components lastObject];
            NSLog(@"ACCESS TOKEN = %@",accessToken);
            [[InstagramEngine sharedEngine] setAccessToken:accessToken];
            [mWebView setHidden:YES];
            [self uploadVideoToInstagram];
        }
        return NO;
    }
    return YES;
}

- (void)uploadVideoToInstagram {
    NSURL *videoFilePath = [NSURL fileURLWithPath:outputFilePath isDirectory:NO]; // Your local path to the video
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoFilePath completionBlock:^(NSURL *assetURL, NSError *error) {
        NSURL *instagramURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://library?AssetPath=%@",[assetURL absoluteString]]];
        if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [[UIApplication sharedApplication] openURL:instagramURL];
        }
    }];
//    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://location?id=1"]]) {
//        
//        NSURL *instagramURL = [NSURL URLWithString:@"instagram://camera"];
//        
//        NSString  *instagramIgo = [NSTemporaryDirectory() stringByAppendingPathComponent:@"instagram.igo"];
//        NSLog(@"video path == %@",instagramIgo);
//        
//        // Save video to library ---
//        
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        // don't forget to link to the AssetsLibrary framework
//        // and also #import <AssetsLibrary/AssetsLibrary.h>
//        
//        NSURL *filePathURL = [NSURL fileURLWithPath:outputFilePath isDirectory:NO];
//        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:filePathURL]) {
//            [library writeVideoAtPathToSavedPhotosAlbum:filePathURL completionBlock:^(NSURL *assetURL, NSError *error){
//                if (error) {
//                    // TODO: error handling
//                } else {
//                    // TODO: success handling
//                }
//            }];
//        }
//        
//        NSURL *fileURL = [NSURL fileURLWithPath:instagramIgo];
//        
//        NSLog(@"---- %@",fileURL);
//        
//        docController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
//        docController.delegate = self;
//        [docController setUTI:@"com.instagram.exclusivegram"];
//        [docController setAnnotation:@{@"InstagramCaption" : @"Cloud Epic Mar"}];
//        [docController presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
//        
//        [[UIApplication sharedApplication] openURL:instagramURL];
//    }
}
- (void) saveToCameraRoll:(NSURL *)srcURL
{
    NSLog(@"srcURL: %@", srcURL);
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock =
    ^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image with metadata to Photo Library %@", newURL.absoluteString);
        }
    };
    
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:srcURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:srcURL
                                    completionBlock:videoWriteCompletionBlock];
    }
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Your Dub has been successfully saving to your Camera Roll!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)hideIndicator {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == ALERT_MESSENGER_TAG) {
        if(buttonIndex == 0) {
            NSData *videoData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:outputFilePath]];
            [FBSDKMessengerSharer shareVideo:videoData withOptions:nil];
        }
    }
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
