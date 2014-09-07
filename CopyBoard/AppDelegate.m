//
//  AppDelegate.m
//  CopyBoard
//
//  Created by Katie Siegel on 9/6/14.
//  Copyright (c) 2014 Kathryn Siegel. All rights reserved.
//

#import "AppDelegate.h"
#include <stdlib.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [GrowlApplicationBridge setGrowlDelegate:self];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    code = [prefs stringForKey:@"copycopycode"];
    if (!code) {
        code = [self generateCopyCopyCode];
        NSLog(@"code: %@",code);
    }
    [self.codeField setStringValue:code];
    [prefs setObject:code forKey:@"copycopycode"];
    
    pboard = [NSPasteboard generalPasteboard];
    changeCount = [pboard changeCount];
	
	timer = [NSTimer scheduledTimerWithTimeInterval:0.5f
											  target:self
											selector:@selector(checkPasteboardCount:)
											userInfo:nil
											 repeats:YES];
    pollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(checkServer:) userInfo:nil repeats:YES];
}

- (void)checkPasteboardCount:(NSTimer *)timer {
    if(changeCount != [pboard changeCount]) {
        changeCount = [pboard changeCount];
		
		NSData *data;
        NSString *str;
		
		data = [pboard dataForType:@"NSStringPboardType"];
		if (data){
            str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSLog(@"String: %@",str);
            [self postToServer: str];
		}
    }
}

- (void) checkServer:(NSTimer*)timer {
//    NSLog(@"get request started");
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    NSString* params = [[NSString stringWithFormat:@"authToken=%@",[self stripSpaces:code]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://copycopy.herokuapp.com/mac?%@",params]]];
    [request setHTTPMethod:@"GET"];
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(theConnection) {
//        NSLog(@"connection initiated: %@",request);
    }

}

- (void)postToServer: (NSString*)str {
//    NSLog(@"web request started");
    NSString *post = [NSString stringWithFormat:@"text=%@&authToken=%@", str, [self stripSpaces:code]];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];
    NSString *postLength = [NSString stringWithFormat:@"%ld", (unsigned long)[postData length]];
    
//    NSLog(@"Post data: %@", post);
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:@"http://copycopy.herokuapp.com/"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
//    NSLog(@"request: %@",request);
    
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if(theConnection) {
//        NSLog(@"connection initiated 2: %@",request);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"connection received data: %@",[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions
                          error:&error];
    
    NSString* text = [json objectForKey:@"text"];
    if (text) {
        NSLog(@"text received: %@",text);
        [self sendGrowlNotification:text];
        [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pboard setString:text forType:NSStringPboardType];
        changeCount = [pboard changeCount];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse *ne = (NSHTTPURLResponse *)response;
//    NSLog(@"connection received response %@",response);
    if([ne statusCode] == 200) {
//        NSLog(@"connection state is 200 - all okay");
    } else {
//        NSLog(@"connection state is NOT 200");
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
//    NSLog(@"Conn Err: %@", [error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    NSLog(@"Conn finished loading");
}

- (NSString*) generateCopyCopyCode {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"words"
                                                     ofType:@"txt"];
    NSLog(@"path: %@",path);
    NSString* content = [NSString stringWithContentsOfFile:path
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    NSArray *words = [content componentsSeparatedByString:@"\t"];
    NSString *wordCombo = @"";
    for (int i=0; i<5; i++) {
        int r = arc4random_uniform((u_int32_t)words.count);
        wordCombo = [NSString stringWithFormat:@"%@ %@",wordCombo,[words objectAtIndex:r]];
    }
    return [wordCombo uppercaseString];
}

- (IBAction)codeButtonPressed:(id)sender {
    NSError *error;
    NSString *pattern = @"[a-zA-Z]{4} [a-zA-Z]{4} [a-zA-Z]{4} [a-zA-Z]{4} [a-zA-Z]{4}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"Error with regular expression");
    } else {
        NSString* theWord = self.codeInput.stringValue;
        NSLog(@"%@",theWord);
        if ([regex matchesInString:theWord options:0 range:(NSRange){0, [theWord length]}] && theWord.length ==24) {
            [self setStoredCode:self.codeInput.stringValue];
        } else {
            [self.errorField setStringValue:@"ERROR: code must be five four-letter words"];
        }
    }
    
}

- (IBAction)useNewCodeButtonPressed:(id)sender {
    [self setStoredCode:self.codeField.stringValue];
}

- (void) setStoredCode: (NSString*)nCode {
    [self.errorField setStringValue:@""];
    code = nCode;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:code forKey:@"copycopycode"];
    [self.currentCode setStringValue:code];
}

- (void) sendGrowlNotification: (NSString*)text {
    [GrowlApplicationBridge notifyWithTitle:@"CopyCopy" description:@"New text copied to clipboard."
                           notificationName:@"CopyCopy" iconData:nil priority:1 isSticky:YES clickContext:nil];
    
}

- (NSDictionary *) registrationDictionaryForGrowl {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"Growl Registration Ticket.growlRegDict" ofType:@"plist"];
    NSDictionary* configs = [NSDictionary dictionaryWithContentsOfFile:path];
    return configs;
}

- (NSString*) stripSpaces: (NSString*)str {
    return [str stringByReplacingOccurrencesOfString:@" " withString:@""];
}
@end
