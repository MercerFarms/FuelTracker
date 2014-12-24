//
//  InetConnect.h
//  FuelTracker
//
//  Created by Peter Tucker on 8/22/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "Data.h"

extern NSString* SYNCFILE;

@interface Submit : NSObject<NSXMLParserDelegate, MFMailComposeViewControllerDelegate> {
    int saveNotify;
    int failNotify;
    NSMutableArray* savesInProgress;
    NSString* errMsg;
    NSMutableData* inetdata;
    NSString* currentElement;
    NSMutableString* xmldata;
    
    void (^onComplete)(BOOL, NSString*);
    
    UIViewController* parent;
}

-(id)init;
-(void)submitToServerOnComplete:(void (^)(BOOL success, NSString* msg))complete;
-(void)submitToServerWithBody:(NSString*)body onComplete:(void (^)(BOOL success, NSString* msg))complete;

@end
