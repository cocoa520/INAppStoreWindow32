//
//  AppDelegate.m
//  Xcode8Demo
//
//  Created by admin on 2017/1/15.
//  Copyright © 2017年 wondershare. All rights reserved.
//

#import "AppDelegate.h"
#import "INAppStoreWindow.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    INAppStoreWindow* aWindow = (INAppStoreWindow*)window;
    aWindow.titleBarHeight = 60.0;
    aWindow.trafficLightButtonsLeftMargin = 13.0;
    aWindow.title = @"Hello Window.";
    //aWindow.titleTextColor = [NSColor blueColor];
//    aWindow.titleTextShadow = nil;
    aWindow.titleBarDrawingBlock = ^(BOOL drawsAsMainWindow, CGRect drawingRect,CGRectEdge edge, CGPathRef clippingPath){
//        [[NSColor blueColor] setFill];
//        NSRectFill(NSRectFromCGRect(drawingRect));
    };
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
