//
//  AppDelegate.h
//  CopyBoard
//
//  Created by Katie Siegel on 9/6/14.
//  Copyright (c) 2014 Kathryn Siegel. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Growl/Growl.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSURLConnectionDelegate, GrowlApplicationBridgeDelegate> {
    NSPasteboard *pboard;
    long changeCount;
    NSTimer *timer;
    NSTimer *pollingTimer;
    NSString *code;
    __weak NSTextField *_codeField;
    __weak NSTextField *_codeInput;
    __weak NSTextField *_currentCode;
    __weak NSTextField *_errorField;
}

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *codeField;
@property (weak) IBOutlet NSTextField *codeInput;
- (IBAction)codeButtonPressed:(id)sender;
- (IBAction)useNewCodeButtonPressed:(id)sender;

@property (weak) IBOutlet NSTextField *currentCode;
@property (weak) IBOutlet NSTextField *errorField;
@end
