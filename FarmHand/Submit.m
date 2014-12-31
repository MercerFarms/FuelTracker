//
//  InetConnect.m
//  FuelTracker
//
//  Created by Peter Tucker on 8/22/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "Submit.h"

NSString* SYNCFILE = @"syncfile.txt";

@implementation Submit

-(id)init {
    saveNotify = 1;
    failNotify = 1;
    
    return self;
}

-(void)submitToServerWithBody:(NSString*)body onComplete:(void (^)(BOOL success, NSString* msg))complete {
    onComplete = complete;
    
    if ([body length] == 0) return;
    
    errMsg = nil;
    NSString* surl = [NSString stringWithFormat:@"http://www.mercerdata.com/newservice.php?farmid=%d", FarmID];
    NSURL* url = [NSURL URLWithString:surl];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url
                                                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                   timeoutInterval:30];
    
    [req setHTTPMethod:@"post"];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    inetdata = [[NSMutableData alloc] init];
    
    NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:req
                                           delegate:self
                                   startImmediately:YES];
    
    if (savesInProgress == nil)
        savesInProgress = [[NSMutableArray alloc] init];
    [savesInProgress addObject:body];
}

-(void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    [inetdata appendData:data];
}

-(void)connection:(NSURLConnection*)conn didFailWithError:(NSError *)error {
    NSString* body = [[NSString alloc] initWithData:[[conn originalRequest] HTTPBody] encoding:NSUTF8StringEncoding];

    [self saveFailed:@"There was a failure connecting to the server. Your data has been saved to this device. When you have a reliable Internet connection, press 'Save to server'."
             forBody:body];
}

-(void)saveFailed:(NSString*)msg forBody:(NSString*)body {
    errMsg = msg;
    
    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* failfile = [docdir stringByAppendingPathComponent:SYNCFILE];
    NSString* fails = [NSString stringWithContentsOfFile:failfile encoding:NSUTF8StringEncoding error:nil];
    if (!fails) fails = [[NSString alloc] init];
    fails = [NSString stringWithFormat:@"%@%@%@", fails, [fails length] == 0 ? @"" : @"\n", body];
    NSError* err;
    [fails writeToFile:failfile atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    failNotify--;
    if (failNotify == 0) {
        onComplete(NO, errMsg);
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection*) conn {
    NSString* body = [[NSString alloc] initWithData:[[conn originalRequest] HTTPBody] encoding:NSUTF8StringEncoding];
    [savesInProgress removeObject:body];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inetdata];
    [parser setDelegate:self];
    [parser parse];
    
    saveNotify--;
    if (saveNotify == 0 && failNotify > 0 && errMsg == nil)
        onComplete(YES, nil);
    else {
        [self saveFailed:errMsg forBody:body];
        onComplete(NO, errMsg);
    }
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

-(void)sendEmailFromViewController:(UIViewController*) vc {
    parent = vc;
    
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        [mailer setMailComposeDelegate: self];
        [mailer setSubject:@"Service Report"];
        
        [mailer setToRecipients:[NSArray arrayWithObject:@"nat.cowell@mercercanyons.com"]];
        
        //UIImage *myImage = [UIImage imageNamed:@"mobiletuts-logo.png"];
        //NSData *imageData = UIImagePNGRepresentation(myImage);
        //[mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"mobiletutsImage"];
        
        NSMutableString *emailBody = [NSMutableString stringWithFormat:@"Timestamp: %@\n", Timestamp];
        [emailBody appendString:[NSString stringWithFormat:@"Field: %@\n", FieldName]];
        [emailBody appendString:[NSString stringWithFormat:@"Fuel Truck Operator: %@\n",
                                 FuelTruckOperatorID]];
        [emailBody appendString:[NSString stringWithFormat:@"Unit #: %@\n", UnitID]];
        [emailBody appendString:[NSString stringWithFormat:@"Implement #: %@\n", ImplementID]];
        [emailBody appendString:[NSString stringWithFormat:@"Operator #: %@\n", OperatorID]];
        
        [emailBody appendString:[NSString stringWithFormat:@"Unit Hours: %@\n", UnitHours]];
        [emailBody appendString:[NSString stringWithFormat:@"Service Reminder: %@\n", Reminders]];
        [emailBody appendString:[NSString stringWithFormat:@"Gallons of Diesel: %@\n", GallonsDiesel]];
        [emailBody appendString:[NSString stringWithFormat:@"Gallons of DEF: %@\n", GallonsDEF]];
        [emailBody appendString:[NSString stringWithFormat:@"Motor Oil? %@\n", MotorOil ? @"Yes" : @"No"]];
        [emailBody appendString:[NSString stringWithFormat:@"Hydraulic Oil? %@\n",
                                 HydraulicOil ? @"Yes" : @"No"]];
        [emailBody appendString:[NSString stringWithFormat:@"Inspection? %@\n",
                                 Inspection ? @"Yes" : @"No"]];
        
        [mailer setMessageBody:emailBody isHTML:NO];
        
        [parent presentViewController:mailer animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't support sending email"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    
    // Remove the mail view
    [parent dismissViewControllerAnimated:YES completion:nil];
}


@end
