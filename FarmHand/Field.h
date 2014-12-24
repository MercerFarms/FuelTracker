//
//  Field.h
//  FarmHand
//
//  Created by Peter Tucker on 6/12/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Field : NSObject {
    NSString* name;
    double latitude, longitude;
}

@property double latitude;
@property double longitude;

-(id)initWithName:(NSString*)n latitude:(double) la longitude:(double) lo;
-(NSString*)description;

@end
