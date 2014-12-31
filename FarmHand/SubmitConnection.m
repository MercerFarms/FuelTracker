//
//  SubmitConnection.m
//  FuelTracker
//
//  Created by Peter Tucker on 12/31/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "SubmitConnection.h"
#import "Submit.h"

@implementation SubmitConnection
@synthesize body;

-(id)initWithBody:(NSString *)b forParent:(Submit *)p {
    body = b;
    parent = p;
    
    return self;
}

-(void)start {
    NSString* surl = [NSString stringWithFormat:@"http://www.mercerdata.com/newservice.php?farmid=%d", FarmID];
    NSURL* url = [NSURL URLWithString:surl];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:30];
    
    [req setHTTPMethod:@"post"];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    inetdata = [[NSMutableData alloc] init];
    
    conn = [[NSURLConnection alloc] initWithRequest:req
                                           delegate:self
                                   startImmediately:YES];
}

-(void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    [inetdata appendData:data];
}

-(void)connection:(NSURLConnection*)conn didFailWithError:(NSError *)error {
    [parent submitFinished:self withError:@"There was a failure connecting to the server. Your data has been saved to this device. When you have a reliable Internet connection, press 'Save to server'."];
}

-(void)connectionDidFinishLoading:(NSURLConnection*) c {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inetdata];
    [parser setDelegate:self];
    [parser parse];
    
    [parent submitFinished:self withError:errMsg];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    currentElement = elementName;
    if ([elementName isEqualToString:@"err"]) {
        xmldata = [[NSMutableString alloc] init];
    }
    else if ([elementName isEqualToString:@"sql"]) {
        xmldata = [[NSMutableString alloc] init];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([currentElement isEqualToString:@"err"] || [currentElement isEqualToString:@"sql"])
        [xmldata appendString:string];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"err"]) {
        [xmldata appendString:@". Your data has been saved to this device. You can re-save later by pressing 'Save to server'"];
        errMsg = xmldata;
    }
    /*
     else if ([elementName isEqualToString:@"sql"]) {
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SQL"
     message:xmldata
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
     [alert show];
     }
     */
}
@end
