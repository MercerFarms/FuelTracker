//
//  ViewController.h
//  FarmHand
//
//  Created by Peter Tucker on 6/8/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Submit.h"


@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, NSXMLParserDelegate> {
    IBOutlet UILabel* lblFuelTruckOperator;
    IBOutlet UILabel* lblField;
    IBOutlet UILabel* lblUnit;
    IBOutlet UILabel* lblImplement;
    IBOutlet UILabel* lblOperator;
    
    IBOutlet UITextField* textFuelTruckOperator;
    IBOutlet UITableView* tableFields;
    IBOutlet UITextField* textUnit;
    IBOutlet UITextField* textImplement;
    IBOutlet UITextField* textOperator;
    
    IBOutlet UIButton* btnStartMeter;
    IBOutlet UIButton* btnEndMeter;

    IBOutlet UIButton* btnReset;
    IBOutlet UIButton* btnNext;
    IBOutlet UIButton* btnSync;
    
    IBOutlet UISwitch* switchLanguage;
    
    //DEBUG
    IBOutlet UILabel* lblLatitude;
    IBOutlet UILabel* lblLongitude;
    int cLocations;
    //DEBUG
    
    NSArray* fields;
    NSMutableArray* fieldsStore;
    NSMutableData* inetdata;
    double latMin, latMax, longMin, longMax;
    int locationErrorAlert;
    
    NSUserDefaults* defs;
    
    Submit* conn;
    
    BOOL isSorting;
}

@property (strong, nonatomic) CLLocationManager* locationManager;
@property (strong, nonatomic) CLLocation* currentLoc;

-(IBAction)changeLanguage:(id)sender;
-(IBAction)reset:(id)sender;
-(IBAction)syncData:(id)sender;
-(IBAction)submitStartMeterToServer:(id)sender;
-(IBAction)submitEndMeterToServer:(id)sender;

@end
