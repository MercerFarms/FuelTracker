//
//  SecondViewController.m
//  FarmHand
//
//  Created by Peter Tucker on 6/8/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "SecondViewController.h"
#import "Data.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    defs = [NSUserDefaults standardUserDefaults];
    if ([defs stringForKey:@"Language"] != nil &&
        [[defs stringForKey:@"Language"] isEqualToString:@"English"]) {
        [self goEnglish];
        [switchLanguage setOn:false];
    }
    else {
        [self goSpanish];
        [switchLanguage setOn:true];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [self changeLanguage:nil];
    
    reminders = [[NSMutableArray alloc] init];
    [reminders addObject:@"Needs Service"];
    [reminders addObject:@"Overdue"];
    [reminders addObject:@"Accepable"];
    [reminders addObject:@"Not Applicable"];
    [reminders addObject:@"No Service Sticker"];
    
    [textGallonsDEF setKeyboardType:UIKeyboardTypeNumberPad];
    [textGallonsDiesel setKeyboardType:UIKeyboardTypeNumberPad];
    [textReminders setKeyboardType:UIKeyboardTypeNumberPad];
    [textUnitHours setKeyboardType:UIKeyboardTypeNumberPad];
    
    [textUnitHours setText:UnitHours];
    [textReminders setText:Reminders];
    [textGallonsDiesel setText:GallonsDiesel];
    [textGallonsDEF setText:GallonsDEF];
    [switchMotorOil setOn:MotorOil];
    [switchHydraulicOil setOn:HydraulicOil];
    [switchInspection setOn:Inspection];
    
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM/dd/yyyy HH:mm:ss"];
	[lblTimestamp setText: [dateFormatter stringFromDate:[NSDate date]]];
    
    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* failfile = [docdir stringByAppendingPathComponent:SYNCFILE];
    NSFileManager* fmgr = [NSFileManager defaultManager];
    BOOL exists = ([fmgr fileExistsAtPath:failfile]);
    [btnSync setHidden:!exists];
}

-(void)viewWillDisappear:(BOOL)animated {
    UnitHours = [textUnitHours text];
    Reminders = [textReminders text];
    GallonsDiesel = [textGallonsDiesel text];
    GallonsDEF = [textGallonsDEF text];
    Timestamp = [lblTimestamp text];
    MotorOil = [switchMotorOil isOn];
    HydraulicOil = [switchHydraulicOil isOn];
    Inspection = [switchInspection isOn];
}

-(IBAction)changeLanguage:(id)sender {
    NSString* lang = @"English";
    if ([switchLanguage isOn]) {
        [self goSpanish];
        lang = @"Spanish";
    }
    else
        [self goEnglish];
    
    [defs setObject:lang forKey:@"Language"];
    [defs synchronize];
}

-(IBAction)saveData:(id)sender {
    UnitHours = [textUnitHours text];
    Reminders = [textReminders text];
    GallonsDiesel = [textGallonsDiesel text];
    GallonsDEF = [textGallonsDEF text];
    Timestamp = [lblTimestamp text];
    MotorOil = [switchMotorOil isOn];
    HydraulicOil = [switchHydraulicOil isOn];
    Inspection = [switchInspection isOn];

    if ([self canSave]) {
        //[self sendEmail];
        [self submitToServer];
    }
}

-(IBAction)syncData:(id)sender {
    NSFileManager* fmgr = [NSFileManager defaultManager];
    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* failfile = [docdir stringByAppendingPathComponent:SYNCFILE];
    if ([fmgr fileExistsAtPath:failfile] == NO) return;
    
    NSArray* resends = [[NSString stringWithContentsOfFile:failfile
                                                  encoding:NSUTF8StringEncoding error:nil]
                        componentsSeparatedByString:@"\n"];
    [[NSFileManager defaultManager] removeItemAtPath:failfile error:nil];
    
    [btnSave setEnabled:NO];
    [btnSync setEnabled:NO];
    
    if (conn == nil)
        conn = [[Submit alloc] init];
    for (NSString* body in resends) {
        [conn submitToServerWithBody:body onComplete:^(BOOL s, NSString* m) {
            [self submitComplete:s withMessage:m];
        }];
    }
}

-(void)submitToServer {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	NSString* ts = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString* body = [NSString stringWithFormat:@"FuelID=%@&OpID=%@&UnitID=%@&ImpID=%@&Field=%@&UnitHours=%@&ServiceDue=%@&Diesel=%@&DEF=%@&MotorOil=%@&HydraulicOil=%@&CabInsp=%@&Time=%@",
                      FuelTruckOperatorID, OperatorID, UnitID, ImplementID, FieldName, UnitHours,
                      Reminders, GallonsDiesel, GallonsDEF, (MotorOil ? @"1" : @"0"),
                      (HydraulicOil ? @"1" : @"0"), (Inspection ? @"1" : @"0"), ts
                      ];
    
    [btnSave setEnabled:NO];
    [btnSync setEnabled:NO];

    if (conn == nil)
        conn = [[Submit alloc] init];
    [conn submitToServerWithBody:body onComplete:^(BOOL s, NSString* m) {
        [self submitComplete:s withMessage:m];
    }];
}

-(void)submitComplete:(BOOL)success withMessage:(NSString*)msg {
    if (success) {
        [btnSync setHidden:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save to server succeeded"
                                                        message:@"Data was successfully saved to the server."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        [btnSync setHidden:NO];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save to server failed"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [btnSave setEnabled:YES];
    [btnSync setEnabled:YES];
}

-(void)goEnglish {
    [lblUnitHours setText:@"Unit Hours"];
    [lblService setText:@"Service Due"];
    [lblGallonsDiesel setText:@"Gallons of Diesel"];
    [lblGallonsDEF setText:@"Gallons of DEF"];
    [lblMotorOil setText:@"Motor Oil"];
    [lblHydraulicOil setText:@"Hydraulic Oil"];
    [lblInspection setText:@"Cab Inspection"];
    
    [btnSave setTitle:@"save" forState:UIControlStateNormal];
    [btnSync setTitle:@"send to server" forState:UIControlStateNormal];
}

-(void)goSpanish {
    [lblUnitHours setText:@"Horas de la Unidad"];
    [lblService setText:@"Se Necesita Servicio a Las"];
    [lblGallonsDiesel setText:@"Galones de Diesel"];
    [lblGallonsDEF setText:@"Galones de DEF"];
    [lblMotorOil setText:@"Aceite del Motor"];
    [lblHydraulicOil setText:@"Aceite Hidraulico"];
    [lblInspection setText:@"Inspeccion de Cabina"];
    
    [btnSave setTitle:@"guardar" forState:UIControlStateNormal];
    [btnSync setTitle:@"envia al servidor" forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)canSave {
    int ret = 0;
    if ([[textReminders text] length] < 1 || [[textReminders text] length] > 6)
        ret |= 1;
    if ([[textGallonsDiesel text] length] < 1 || [[textGallonsDiesel text] length] > 4)
        ret |= 2;
    if (![Data isNumber:[textGallonsDEF text]] || ![Data isNumber:[textGallonsDiesel text]] ||
        ![Data isNumber:[textUnitHours text]])
        ret |= 4;
    
    if (ret != 0) {
        NSString* title = [switchLanguage isOn] ? @"Información Inválida" : @"Invalid Information";
        NSString* msg = @"";
        if (ret & 1)
            msg = [switchLanguage isOn] ?
                   @"Necesario: Se necesita servicio a las" : @"Required: Service due";
        if (ret & 2)
            msg = [NSString stringWithFormat:@"%@\n%@", [switchLanguage isOn] ?
                   @"Necesario: galones de diesel" : @"Required: gallons of diesel", msg];
        if (ret & 4)
            msg = [NSString stringWithFormat:@"%@\n%@", [switchLanguage isOn] ?
                   @"Horas de la Unidad, Galones de DEF y Galones de Diesel debe ser un número" :
                   @"Unit Hours, Gallons of Diesel, and Gallons of DEF must be a number", msg];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    return ret == 0;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
