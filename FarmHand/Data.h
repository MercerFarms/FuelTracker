//
//  Data.h
//  FuelTracker
//
//  Created by Peter Tucker on 7/9/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <Foundation/Foundation.h>

extern int FarmID;

extern NSString* FieldName;
extern NSString* FuelTruckOperatorID;
extern NSString* UnitID;
extern NSString* ImplementID;
extern NSString* OperatorID;

extern NSString* UnitHours;
extern NSString* Reminders;
extern NSString* GallonsDiesel;
extern NSString* GallonsDEF;
extern NSString* Timestamp;
extern BOOL MotorOil;
extern BOOL HydraulicOil;
extern BOOL Inspection;
extern BOOL DidSave;

@interface Data : NSObject

+(BOOL) isNumber:(NSString*) s;

@end
