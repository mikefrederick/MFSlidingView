//
//  MFSlidingView.h
//
//  Created by Michael Frederick on 7/13/11.
//  Copyright 2011 University of Wisconsin - Madison. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    LeftOfScreen,
    RightOfScreen,
    AboveScreen,
    BelowScreen
} SlidingViewOffScreenPosition;

typedef enum {
    BottomOfScreen,
    MiddleOfScreen,
    TopOfScreen
} SlidingViewOnScreenPosition;

typedef enum {
    ShowToolbar = 1,
    ShowDoneButton = 2,
    ShowCancelButton = 4,
    AvoidKeyboard = 8,
    CancelOnBackgroundPressed = 16,
    FitSizeToContentView = 32,
    PositionToolbarOnBottom = 64
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