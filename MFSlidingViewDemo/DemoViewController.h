//
//  MFViewController.h
//  MFSlidingViewDemo
//
//  Created by Michael Frederick on 5/3/12.
//  Copyright (c) 2012 Michael Frederick. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSlidingView.h"

@interface DemoViewController : UIViewController<UIActionSheetDelegate> {
    IBOutlet UIView *view1;
    IBOutlet UIView *view2;
}

- (IBAction)buttonPressed:(id)sender;

@end
