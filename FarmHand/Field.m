//
//  Field.m
//  FarmHand
//
//  Created by Peter Tucker on 6/12/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "Field.h"

@implementation Field
@synthesize latitude, longitude;

-(id)initWithName:(NSString *)n latitude:(double)la longitude:(double)lo {
    name = n;
    latitude = la;
    longitude = lo;
    
    return self;
}

-(NSString*)description {
    return name;
}

@end
