//
//  DMVideoShareViewController.h
//  Dubsmash
//
//  Created by Altair on 4/29/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <InstagramKit/InstagramKit.h>

@interface DMVideoShareViewController : UIViewController<UIAlertViewDelegate, MFMessageComposeViewControllerDelegate, UIWebViewDelegate, UIDocumentInteractionControllerDelegate>
{
    
}
@property (nonatomic, retain) IBOutlet UIWebView *mWebView;

@end

