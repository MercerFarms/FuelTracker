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
    connections = [[NSMutableDictionary alloc] init];
    
    return self;
}

-(void)submitToServerWithBody:(NSString*)body onComplete:(void (^)(BOOL success, NSString* msg))complete {
    onComplete = complete;
    
    //Make sure we have a body, and that we're not already submitting that.
    if ([body length] == 0 || [connections objectForKey:body] != nil) return;
    
    if ([connections count] == 0) {
        failNotify = 1;
    }
    SubmitConnection* sc = [[SubmitConnection alloc] initWithBody:body forParent:self];
    [connections setObject:sc forKey:body];
    [sc start];
}

-(void)submitFinished:(SubmitConnection *)sc withError:(NSString*)err {
    [connections removeObjectForKey:[sc body]];

    if ([err length] > 0)
        [self saveFailed:err forBody:[sc body]];
    else
        [self saveSucceededForBody:[sc body]];
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
    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* failfile = [docdir stringByAppendingPathComponent:SYNCFILE];
    NSString* fails = [NSString stringWithContentsOfFile:failfile encoding:NSUTF8StringEncoding error:nil];
    if (!fails) fails = [[NSString alloc] init];
    fails = [NSString stringWithFormat:@"%@%@%@", fails, [fails length] == 0 ? @"" : @"\n", body];
    NSError* err;
    [fails writeToFile:failfile atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    failNotify--;
    if (failNotify == 0) {
        onComplete(NO, msg);
    }
}

-(void)saveSucceededForBody:(NSString*) body {
    if ([connections count] == 0 && failNotify > 0)
        onComplete(YES, nil);
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
