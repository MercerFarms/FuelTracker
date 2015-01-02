//
//  Data.m
//  FuelTracker
//
//  Created by Peter Tucker on 7/9/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "Data.h"

int FarmID = 1; //ID in database for Mercer Farms

NSString* FieldName;
NSString* FuelTruckOperatorID;
NSString* UnitID;
NSString* ImplementID;
NSString* OperatorID;

NSString* UnitHours;
NSString* Reminders;
NSString* GallonsDiesel;
NSString* GallonsDEF;
NSString* Timestamp;
BOOL MotorOil = false;
BOOL HydraulicOil = false;
BOOL Inspection = false;
BOOL DidSave = false;

@implementation Data

+(BOOL) isNumber:(NSString*) s {
    NSNumberFormatter* frm = [[NSNumberFormatter alloc] init];
    [frm setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber* num = [frm numberFromString:s];
    return num != nil;
}

@end
