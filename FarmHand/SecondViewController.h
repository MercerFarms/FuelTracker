//
//  SecondViewController.h
//  FarmHand
//
//  Created by Peter Tucker on 6/8/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
#import "Submit.h"

@interface SecondViewController : UIViewController {
    IBOutlet UILabel* lblUnitHours;
    IBOutlet UILabel* lblService;
    IBOutlet UILabel* lblGallonsDiesel;
    IBOutlet UILabel* lblGallonsDEF;
    IBOutlet UILabel* lblMotorOil;
    IBOutlet UILabel* lblHydraulicOil;
    IBOutlet UILabel* lblInspection;
    IBOutlet UILabel* lblTimestamp;
    
    IBOutlet UITextField* textUnitHours;
    IBOutlet UITextField* textReminders;
    IBOutlet UITextField* textGallonsDiesel;
    IBOutlet UITextField* textGallonsDEF;
    IBOutlet UISwitch* switchMotorOil;
    IBOutlet UISwitch* switchHydraulicOil;
    IBOutlet UISwitch* switchInspection;
    
    IBOutlet UIButton* btnSave;
    IBOutlet UIButton* btnSync;

    IBOutlet UISwitch* switchLanguage;
    
    NSMutableArray* reminders;
    Submit* conn;
    NSUserDefaults* defs;
}

-(IBAction)changeLanguage:(id)sender;
-(IBAction)saveData:(id)sender;
-(IBAction)syncData:(id)sender;

@end
