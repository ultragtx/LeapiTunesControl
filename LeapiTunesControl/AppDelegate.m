//
//  AppDelegate.m
//  LeapiTunesControl
//
//  Created by Xinrong Guo on 13-2-27.
//  Copyright (c) 2013年 Xinrong Guo. All rights reserved.
//

#import "AppDelegate.h"
#import "LeapObjectiveC.h"
#import "LogTools.h"
#import "iTunes.h"

#define strLeapStatusInitializing @"Initializing"
#define strLeapStatusInitialized @"Initialized"
#define strLeapStatusConnected @"Connected"
#define strLeapStatusDisconnected @"Disconnected"
#define strLeapStatusExited @"Exited"

typedef enum  {
    SwipeGestureDirection_None,
    SwipeGestureDirection_Forward,
    SwipeGestureDirection_Backward,
}SwipeGestureDirection;

@interface AppDelegate ()

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSMenuItem *leapStatusMenuItem;
@property (strong, nonatomic) LeapController *controller;
@property (strong, nonatomic) NSTimer *timer;

@property (assign, atomic) SwipeGestureDirection swipeGestureDirection;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSImage *menuIcon = [NSImage imageNamed:@"MenuBarIcon.pdf"];
    [menuIcon setTemplate:YES];
    
    NSMenu *statusMenu = [[NSMenu alloc] initWithTitle:@"StatusMenu"];
    _leapStatusMenuItem = [[NSMenuItem alloc] initWithTitle:strLeapStatusInitializing action:nil keyEquivalent:@""];
    
    [statusMenu addItem:_leapStatusMenuItem];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setImage:menuIcon];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:statusMenu];
    
    // iTunes
    [self initItunes];
    
    // Leap Part
    [self initLeap];
    
    // Gesture
    self.swipeGestureDirection = SwipeGestureDirection_None;
    
    // Timer
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkGestureStatus) userInfo:nil repeats:YES];
    [_timer fire];
}

- (void)checkGestureStatus {
    SwipeGestureDirection currentDirection = self.swipeGestureDirection;
    switch (currentDirection) {
        case SwipeGestureDirection_Forward:
            [self nextTrack];
            break;
        case SwipeGestureDirection_Backward:
            [self previousTrack];
            break;
            
        default:
            break;
    }
    
    self.swipeGestureDirection = SwipeGestureDirection_None;
}


#pragma mark - iTunes

- (void)initItunes {
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    NSLog(@"Current song is %@", [[iTunes currentTrack] name]);
}

- (void)playPause {
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if ([iTunes isRunning]) {
        DLog(@"iTunes Pause");
        [iTunes playpause];
    }
}

- (void)nextTrack {
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if ([iTunes isRunning]) {
        [iTunes nextTrack];
    }
}

- (void)previousTrack {
    iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    if ([iTunes isRunning]) {
        [iTunes previousTrack];
    }
}

#pragma mark - Leap

- (void)initLeap {
    _controller = [[LeapController alloc] init];
    [_controller addListener:self];
    DLog(@"running");
    [_leapStatusMenuItem setTitle:strLeapStatusInitializing];
}

#pragma mark - Leap Listener

- (void)onInit:(NSNotification *)notification {
    NSLog(@"Initialized");
    [_leapStatusMenuItem setTitle:strLeapStatusInitialized];
}

- (void)onConnect:(NSNotification *)notification {
    NSLog(@"Connected");
    [_leapStatusMenuItem setTitle:strLeapStatusConnected];
    LeapController *aController = (LeapController *)[notification object];
    [aController enableGesture:LEAP_GESTURE_TYPE_CIRCLE enable:YES];
//    [aController enableGesture:LEAP_GESTURE_TYPE_KEY_TAP enable:YES];
//    [aController enableGesture:LEAP_GESTURE_TYPE_SCREEN_TAP enable:YES];
    [aController enableGesture:LEAP_GESTURE_TYPE_SWIPE enable:YES];
}

- (void)onDisconnect:(NSNotification *)notification {
    [_leapStatusMenuItem setTitle:strLeapStatusDisconnected];
    NSLog(@"Disconnected");
}

- (void)onExit:(NSNotification *)notification {
    [_leapStatusMenuItem setTitle:strLeapStatusExited];
    NSLog(@"Exited");
}

- (void)onFrame:(NSNotification *)notification {
    //    NSLog(@"OnFrame");
    LeapController *aController = (LeapController *)[notification object];
    
    // Get the most recent frame and report some basic information
    LeapFrame *frame = [aController frame:0];
    
    NSArray *gestures = [frame gestures:nil];
    if (gestures.count > 0) {
        LeapGesture *gesture = [gestures objectAtIndex:0];

        switch (gesture.type) {
            /*case LEAP_GESTURE_TYPE_CIRCLE: {
                 LeapCircleGesture *circleGesture = (LeapCircleGesture *)gesture;
                 // Calculate the angle swept since the last frame
                 float sweptAngle = 0;
                 if(circleGesture.state != LEAP_GESTURE_STATE_START) {
                 LeapCircleGesture *previousUpdate = (LeapCircleGesture *)[[aController frame:1] gesture:gesture.id];
                 sweptAngle = (circleGesture.progress - previousUpdate.progress) * 2 * LEAP_PI;
                 }
                 
                 NSLog(@"Circle id: %d, %@, progress: %f, radius %f, angle: %f degrees",
                 circleGesture.id, [Sample stringForState:gesture.state],
                 circleGesture.progress, circleGesture.radius, sweptAngle * LEAP_RAD_TO_DEG);
                 break;
                 }*/
            case LEAP_GESTURE_TYPE_SWIPE: {
                LeapSwipeGesture *swipeGesture = (LeapSwipeGesture *)gesture;
//                NSLog(@"Swipe id: %d, position: %@, direction: %@, speed: %f", swipeGesture.id, swipeGesture.position, swipeGesture.direction, swipeGesture.speed);
                if (swipeGesture.direction.x > 0) {
                    self.swipeGestureDirection = SwipeGestureDirection_Forward;
                }
                else if (swipeGesture.direction.x < 0) {
                    self.swipeGestureDirection = SwipeGestureDirection_Backward;
                }
                break;
            }
            default:
                break;
        }
    }
}

@end
