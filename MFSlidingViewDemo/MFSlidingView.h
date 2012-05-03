//
//  MFSlidingView.h
//
//  Created by Michael Frederick on 7/13/11.
//  Copyright 2011 Michael Frederick. All rights reserved.
//

#import <UIKit/UIKit.h>

// where should the view slide in from?
typedef enum {
    LeftOfScreen,
    RightOfScreen,
    AboveScreen,
    BelowScreen
} SlidingViewOffScreenPosition;

// where should the view slide in to?
typedef enum {
    BottomOfScreen,
    MiddleOfScreen,
    TopOfScreen
} SlidingViewOnScreenPosition;

typedef enum {
    ShowDoneButton = 1, // show a done button on the toolbar
    ShowCancelButton = 2, // show a cancel button on the toolbar
    AvoidKeyboard = 4, // useful with a uitextfield or uitextview in the content view
    CancelOnBackgroundPressed = 8, // cancelBlock will be executed when background tapped
    PositionToolbarOnBottom = 16 // position the toolbar on the bottom of the content view
} SlidingViewOptions;


@interface MFSlidingView : UIView

+ (MFSlidingView *) slideView:(UIView *)contentView 
          intoView:(UIView *)wrapper 
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition;

+ (MFSlidingView *) slideView:(UIView *)view 
          intoView:(UIView *)wrapper
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition 
 offScreenPosition:(SlidingViewOffScreenPosition)offScreenPosition;

+ (MFSlidingView *) slideView:(UIView *)view
          intoView:(UIView *)wrapper
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition
 offScreenPosition:(SlidingViewOffScreenPosition)offScreenPosition
             title:(NSString *)title
           options:(SlidingViewOptions)options
         doneBlock:(void (^)())doneBlock
       cancelBlock:(void (^)())cancelBlock;

+ (void) slideOut;

@end