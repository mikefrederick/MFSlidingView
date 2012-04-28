//
//  MFSlidingView.m
//
//  Created by Michael Frederick on 7/13/11.
//  Copyright 2011 University of Wisconsin - Madison. All rights reserved.
//

#import "MFSlidingView.h"
#import <QuartzCore/QuartzCore.h>
#import "UI.h"

#define BITMASK_CONTAINS_OPTION(bitmask,option) ((bitmask & option) == option)

typedef void (^MFBlock)(void);

@interface MFSlidingView () {
    UIView *bodyView;
    CGRect framePriorToKeyboardMovement;
}

@property (nonatomic, assign) UIView *containerView;
@property (nonatomic, assign) UIView *contentView;
@property (nonatomic, readonly) BOOL showDoneButton;
@property (nonatomic, readonly) BOOL showCancelButton;
@property (nonatomic, readonly) BOOL showToolbar;
@property (nonatomic, readonly) BOOL avoidKeyboard;
@property (nonatomic, readonly) BOOL fitSizeToContentView;
@property (nonatomic, readonly) BOOL positionToolbarOnBottom;
@property (nonatomic, assign) SlidingViewOptions options;
@property (nonatomic, assign) SlidingViewOnScreenPosition finalPosition;
@property (nonatomic, assign) SlidingViewOffScreenPosition initialPosition;
@property (readwrite, nonatomic, copy) MFBlock doneBlock;
@property (readwrite, nonatomic, copy) MFBlock cancelBlock;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIToolbar *toolbar;

- (id) initWithContentView:(UIView *)view;
- (void) slideIntoView:(UIView *)wrapper;
- (void) slideOut;
- (BOOL) adjustToFirstResponder;

- (CGPoint) offScreenCoordinates;
- (CGPoint) onScreenCoordinates;

- (CGRect)contentFrame;
- (CGRect)bodyFrame;

@end


@implementation MFSlidingView

@synthesize showDoneButton;
@synthesize showCancelButton;
@synthesize showToolbar;
@synthesize avoidKeyboard;
@synthesize fitSizeToContentView;
@synthesize contentView;
@synthesize options;
@synthesize initialPosition;
@synthesize finalPosition;
@synthesize cancelBlock;
@synthesize doneBlock;
@synthesize title;
@synthesize toolbar;
@synthesize containerView;

static MFSlidingView *sharedView = nil;

+ (MFSlidingView *) slideView:(UIView *)contentView 
          intoView:(UIView *)wrapper 
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition {
    SlidingViewOffScreenPosition offScreenPosition;
    switch (onScreenPosition) {
        case BottomOfScreen:
        case MiddleOfScreen:
            offScreenPosition = BelowScreen;
            break;
        case TopOfScreen:
            offScreenPosition = AboveScreen;
            break;
    }
    
    return [MFSlidingView slideView:contentView intoView:wrapper 
            onScreenPosition:onScreenPosition offScreenPosition:offScreenPosition];
}

+ (MFSlidingView *) slideView:(UIView *)view 
          intoView:(UIView *)wrapper
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition 
 offScreenPosition:(SlidingViewOffScreenPosition)offScreenPosition {
    
    SlidingViewOptions options = ShowToolbar|ShowDoneButton|ShowCancelButton|CancelOnBackgroundPressed;
    if(onScreenPosition == MiddleOfScreen) options = options|FitSizeToContentView;
    else if (onScreenPosition == TopOfScreen) options = options|PositionToolbarOnBottom;
    
    return [MFSlidingView slideView:view intoView:wrapper 
            onScreenPosition:onScreenPosition offScreenPosition:offScreenPosition
                       title:nil options:options doneBlock:nil cancelBlock:nil];    
}

+ (MFSlidingView *) slideView:(UIView *)view 
          intoView:(UIView *)wrapper 
  onScreenPosition:(SlidingViewOnScreenPosition)onScreenPosition 
 offScreenPosition:(SlidingViewOffScreenPosition)offScreenPosition
             title:(NSString *)title 
           options:(SlidingViewOptions)options
         doneBlock:(void (^)())doneBlock
       cancelBlock:(void (^)())cancelBlock {
    
    MFSlidingView *slidingView = [[MFSlidingView alloc] initWithContentView:view];
    slidingView.doneBlock = doneBlock;
    slidingView.cancelBlock = cancelBlock;
    slidingView.options = options;
    slidingView.title = title;
    slidingView.initialPosition = offScreenPosition;
    slidingView.finalPosition = onScreenPosition;
    [slidingView slideIntoView:wrapper];
    
    sharedView = slidingView;
    
    return slidingView;
}

+ (void) slideOut {
    if(!sharedView) return;
    [sharedView slideOut];
    sharedView = nil;
}

- (void) dealloc {
    self.toolbar = nil;
    self.title = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithContentView:(UIView *)view {
    self = [super init];
    if (self) {
        // Initialization code
        bodyView = [[UIView alloc] 
                            initWithFrame:CGRectZero];
        [self addSubview:bodyView];
        self.contentView = view;
    }
    return self;
}

- (BOOL) showDoneButton {
    return BITMASK_CONTAINS_OPTION(self.options, ShowDoneButton);
}

- (BOOL) showCancelButton {
    return BITMASK_CONTAINS_OPTION(self.options, ShowCancelButton);
}

- (BOOL) showToolbar {
    if(self.showDoneButton || self.showCancelButton || self.title) return YES;
    return BITMASK_CONTAINS_OPTION(self.options, ShowToolbar);
}

- (BOOL) avoidKeyboard {
    return BITMASK_CONTAINS_OPTION(self.options, AvoidKeyboard);
}

- (BOOL) fitSizeToContentView {
    return BITMASK_CONTAINS_OPTION(self.options, FitSizeToContentView);
}

- (BOOL) positionToolbarOnBottom {
    return BITMASK_CONTAINS_OPTION(self.options, PositionToolbarOnBottom);
}

- (UIBarButtonItem *)doneButtonItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                         target:self action:@selector(donePressed:)];
}

- (UIBarButtonItem *)cancelButtonItem {
    return [[UIBarButtonItem alloc] 
            initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
            target:self action:@selector(cancelPressed:)];
}

- (UIBarButtonItem *)titleButtonItem {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.text = self.title;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:18];
    [label sizeToFit];
    return [[UIBarButtonItem alloc] initWithCustomView:label];
}

- (UIBarButtonItem *)flexButtonItem {
    return [[UIBarButtonItem alloc] 
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
            target:nil action:nil];
}

- (void) drawToolbar {
    if(!self.showToolbar) return;
    
    CGFloat y = (self.positionToolbarOnBottom) ? self.contentFrame.size.height : 0;
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, y, bodyView.frame.size.width, 44)];
    self.toolbar.tintColor = kDarkBlueColor;
    
    NSMutableArray *toolbarItems = [NSMutableArray new];
    
    if(self.showCancelButton) {
        [toolbarItems addObject:self.cancelButtonItem];
        [toolbarItems addObject:self.flexButtonItem];
    }
    
    if(self.title) {
        [toolbarItems addObject:self.titleButtonItem];
        [toolbarItems addObject:self.flexButtonItem];
    }
    
    if(self.showDoneButton) [toolbarItems addObject:self.doneButtonItem];
    
    self.toolbar.items = toolbarItems;
    
    [bodyView addSubview:self.toolbar];
}

- (CGPoint) offScreenCoordinates {
    CGRect frame = [self bodyFrame];
    CGPoint initialCoordinates = CGPointZero;
    CGPoint finalCoordinates = [self onScreenCoordinates];;
    if(self.fitSizeToContentView) {
        initialCoordinates.x = (self.containerView.bounds.size.width - frame.size.width)/2;
    }
    
    switch (self.initialPosition) {
        case BelowScreen:
            initialCoordinates.x = finalCoordinates.x;
            initialCoordinates.y = self.containerView.bounds.size.height;
            break;
        case AboveScreen:
            initialCoordinates.x = finalCoordinates.x;
            initialCoordinates.y = -1*frame.size.height;
            break;
        case LeftOfScreen:
            initialCoordinates.x = -1*frame.size.width;
            initialCoordinates.y = finalCoordinates.y;
            break;
        case RightOfScreen:
            initialCoordinates.x = self.containerView.bounds.size.width + frame.size.width;
            initialCoordinates.y = finalCoordinates.y;
            break;
    }
    
    return initialCoordinates;
}

- (CGPoint) onScreenCoordinates {
    CGRect frame = [self bodyFrame];
    CGPoint finalCoordinates = CGPointZero;
    
    if(self.fitSizeToContentView) {
        finalCoordinates.x = (self.containerView.bounds.size.width - frame.size.width)/2;
    }
    
    switch (self.finalPosition) {
        case TopOfScreen:
            finalCoordinates.y = 0.0;
            break;
        case MiddleOfScreen:
            finalCoordinates.y = (self.containerView.bounds.size.height - frame.size.height)/2;
            break;
        case BottomOfScreen:
            finalCoordinates.y = self.containerView.bounds.size.height - frame.size.height;
            break;
    }
    
    return finalCoordinates;
}

- (CGRect) contentFrame {
    CGRect frame = self.contentView.frame;
    frame.origin.x = 0;
    frame.origin.y = (self.showToolbar && !self.positionToolbarOnBottom) ? 44 : 0;
    return frame;
}

- (CGRect) bodyFrame {
    CGRect frame = bodyView.frame;
    frame.size = self.contentView.frame.size;
    if(self.showToolbar) frame.size.height += 44;
    return frame;
}

- (void) slideIntoView:(UIView *)wrapper
{
    self.containerView = wrapper;
    
    if(self.avoidKeyboard) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWillShow:) 
                                                     name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(keyboardWillHide:) 
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
    
    if(self.fitSizeToContentView) {
        bodyView.backgroundColor = [UIColor blackColor];
        bodyView.clipsToBounds = YES;
        bodyView.layer.cornerRadius = 5;
    }
    
    //set initial location at bottom of view
    CGRect frame = self.frame;
    frame.size = wrapper.frame.size;
    frame.origin = CGPointMake(0, 0);
    self.frame = frame;
    
    self.contentView.frame = [self contentFrame];
    
    frame = [self bodyFrame];
    frame.origin = [self offScreenCoordinates];
    bodyView.frame = frame;
    
    if(self.showToolbar) [self drawToolbar];
    
    [wrapper addSubview:self];
    [bodyView addSubview:self.contentView];
    
    // slide in animation
    [UIView beginAnimations:@"slideIn" context:nil];
    [UIView setAnimationDelegate:self];
    
    frame.origin = [self onScreenCoordinates];
    bodyView.frame = frame;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
   
    [UIView commitAnimations];
    
    framePriorToKeyboardMovement = bodyView.frame;
}

- (void) slideOut
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[UIView beginAnimations:@"slideOut" context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    
    CGRect frame = bodyView.frame;
    frame.origin = [self offScreenCoordinates];
    bodyView.frame = frame;
    self.backgroundColor = [UIColor clearColor];
    
    [UIView commitAnimations]; 
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    if ([animationID isEqualToString:@"slideOut"]) {
        if(self.superview) [self removeFromSuperview];
    } else if ([animationID isEqualToString:@"slideIn"]) {
        
    }
}

- (void) cancelPressed:(id)sender {
    if(self.cancelBlock) self.cancelBlock();
    [self slideOut];
}

- (void) donePressed:(id)sender {
    if(self.doneBlock) self.doneBlock();
    [self slideOut];
}

// Search recursively for first responder
- (UIView*)findFirstResponderBeneathView:(UIView*)view {
    for ( UIView *childView in view.subviews ) {
        if ([childView respondsToSelector:@selector(isFirstResponder)] 
            && [childView isFirstResponder] ) return childView;
        UIView *result = [self findFirstResponderBeneathView:childView];
        if (result) return result;
    }
    return nil;
}

- (BOOL) adjustToFirstResponder {
    UIView *firstResponder = [self findFirstResponderBeneathView:self];
    if (!firstResponder) return NO;
    
    CGRect firstResponderBounds = [firstResponder convertRect:CGRectZero toView:bodyView];
    CGFloat idealPosition = 70;
    
    CGRect frame = bodyView.frame;
    frame.origin.y = idealPosition - firstResponderBounds.origin.y;
    
    // Shrink view's height by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    bodyView.frame = frame;
    [UIView commitAnimations];
    return YES;
}


- (void)keyboardWillShow:(NSNotification*)notification {
    UIView *firstResponder = [self findFirstResponderBeneathView:self];
    if (!firstResponder) return;
    
    framePriorToKeyboardMovement = bodyView.frame;
    
    // Use this view's coordinate system
    CGRect keyboardBounds = [self convertRect:[[[notification userInfo] 
                                                objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] 
                                     fromView:nil];
    CGRect firstResponderBounds = [self convertRect:firstResponder.bounds fromView:firstResponder];
    CGFloat idealPosition = self.frame.size.height - keyboardBounds.size.height - firstResponder.frame.size.height - 30;
    if(firstResponderBounds.origin.y <= idealPosition) return;
    
    CGRect frame = bodyView.frame;
    frame.origin.y -=  firstResponderBounds.origin.y - idealPosition;
    
    CGFloat animationDuration = [[[notification userInfo] 
                                  objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[[notification userInfo] 
                                 objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // Shrink view's height by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    bodyView.frame = frame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    CGFloat animationDuration = [[[notification userInfo] 
                                  objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[[notification userInfo] 
                                 objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // Restore dimensions to prior size
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    bodyView.frame = framePriorToKeyboardMovement;
    
    [UIView commitAnimations];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches) {
        if (CGRectContainsPoint(bodyView.frame, [touch locationInView:self])) return;
    }
    
    if((self.options & CancelOnBackgroundPressed) == CancelOnBackgroundPressed) {
        [self cancelPressed:nil];
    }
}

@end
