//
//  MFViewController.m
//  MFSlidingViewDemo
//
//  Created by Michael Frederick on 5/3/12.
//  Copyright (c) 2012 Michael Frederick. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (IBAction)buttonPressed:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] 
                                  initWithTitle:@"Select A Demo" delegate:self 
                                  cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil 
                                  otherButtonTitles:@"UIDatePicker", @"Random View", 
                                  @"Keyboard Avoidance",
                                  @"View On Top",
                                  nil];
    [actionSheet showInView:self.view];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if([buttonTitle isEqualToString:@"UIDatePicker"]) {
        [MFSlidingView slideView:[[[UIDatePicker alloc] init] autorelease] intoView:self.view 
                onScreenPosition:BottomOfScreen];
    } else if([buttonTitle isEqualToString:@"Random View"]) {
        [MFSlidingView slideView:view1 intoView:self.view 
                onScreenPosition:MiddleOfScreen offScreenPosition:LeftOfScreen];
    } else if([buttonTitle isEqualToString:@"Keyboard Avoidance"]) {
        SlidingViewOptions options = ShowDoneButton|ShowCancelButton|CancelOnBackgroundPressed|AvoidKeyboard;
        void (^cancelOrDoneBlock)() = ^{ 
            // we must manually slide out the view out if we specify this block
            [MFSlidingView slideOut];
        };
        
        [MFSlidingView slideView:view2 intoView:self.view 
                onScreenPosition:BottomOfScreen 
               offScreenPosition:BelowScreen title:@"Avoid Keyboard"
                         options:options 
                       doneBlock:cancelOrDoneBlock 
                     cancelBlock:cancelOrDoneBlock];
    } else if([buttonTitle isEqualToString:@"View On Top"]) {
        [MFSlidingView slideView:view2 intoView:self.view 
                onScreenPosition:TopOfScreen 
               offScreenPosition:AboveScreen title:@"Woohoo"
                         options:ShowDoneButton|ShowCancelButton|CancelOnBackgroundPressed|PositionToolbarOnBottom
                       doneBlock:nil 
                     cancelBlock:nil];
    }
}
       

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
