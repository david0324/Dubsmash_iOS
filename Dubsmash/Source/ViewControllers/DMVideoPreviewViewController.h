//
//  DMVideoPreviewViewController.h
//  Dubsmash
//
//  Created by Altair on 4/28/15.
//  Copyright (c) 2015 Altair. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMVideoPreviewViewController : UIViewController<UITextFieldDelegate>
{
    
}
@property (nonatomic, retain) IBOutlet UIView *videoPlayingView;
@property (nonatomic, retain) IBOutlet UIButton *muteButton;
@property (nonatomic, retain) IBOutlet UITextField *titleTxt;
@property (nonatomic, retain) IBOutlet UILabel *titleMark;
@property (nonatomic, retain) IBOutlet UIView *titleTxtView;

- (void) playMedia;
- (void) stopMedia;
@end
