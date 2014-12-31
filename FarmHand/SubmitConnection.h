//
//  SubmitConnection.h
//  FuelTracker
//
//  Created by Peter Tucker on 12/31/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SubmitConnection : NSObject<NSXMLParserDelegate> {
    NSString* body;
    NSURLConnection* conn;
    NSMutableData* inetdata;
    id parent;
    NSString* errMsg;
    NSString* currentElement;
    NSMutableString* xmldata;
}

@property (retain, readonly) NSString* body;

-(id)initWithBody:(NSString*) b forParent:(id) p;
-(void)start;

@end
