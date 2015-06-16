//
//  ViewController.m
//  FarmHand
//
//  Created by Peter Tucker on 6/8/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "ViewController.h"
#import "Field.h"
#import "Data.h"
#import <math.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    locationErrorAlert = 0;
    cLocations = 0;
    defs = [NSUserDefaults standardUserDefaults];

    if ([defs stringForKey:@"Language"] == nil ||
        [[defs stringForKey:@"Language"] isEqualToString:@"English"]) {
        [self goEnglish];
        [switchLanguage setOn:false];
    }
    else {
        [self goSpanish];
        [switchLanguage setOn:true];
    }
    
    isSorting = false;

    [self setLocationManager:[[CLLocationManager alloc] init]];
    NSString *authorizationVersion = @"8.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    //if this is 8.0 or newer, we have to request authorization
    if ([currSysVer compare:authorizationVersion options:NSNumericSearch] != NSOrderedAscending)
        [[self locationManager] requestAlwaysAuthorization];
    [[self locationManager] setDelegate:self];
    
    DidSave = false;
}

-(void)viewDidAppear:(BOOL)animated {
    [self changeLanguage:nil];
	
    fields = [[NSMutableArray alloc] init];
    [self loadFields];
    
    [textFuelTruckOperator setKeyboardType:UIKeyboardTypeNumberPad];
    [textUnit setKeyboardType:UIKeyboardTypeNumberPad];
    [textOperator setKeyboardType:UIKeyboardTypeNumberPad];
    [textImplement setKeyboardType:UIKeyboardTypeNumberPad];
    
    if (DidSave) {
        [self reset:nil];
        DidSave = false;
    }
    
    [[self locationManager] startUpdatingLocation];

    CLLocation* loc = [[self locationManager] location];
    [self setCurrentLoc: loc];
    [lblLatitude setText:[NSString stringWithFormat:@"(%d) lat: %f",
                          cLocations, [[self currentLoc] coordinate].latitude]];
    [lblLongitude setText:[NSString stringWithFormat:@"(%d) long: %f",
                           cLocations, [[self currentLoc] coordinate].longitude]];

    [self orderFields];
    
    [tableFields setDataSource:self];
    [tableFields setDelegate:self];
    
    [tableFields reloadData];

    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* failfile = [docdir stringByAppendingPathComponent:SYNCFILE];
    NSFileManager* fmgr = [NSFileManager defaultManager];
    BOOL exists = ([fmgr fileExistsAtPath:failfile]);
    [btnSync setHidden:!exists];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[self locationManager] stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //Iterate through your subviews, or some other custom array of views
    for (UIView *view in self.view.subviews)
        [view resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [fields count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 24;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"loadedFields"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"loadedFields"];
    
    CGRect frm = [cell frame];
    frm.size.height = 24;
    [cell setFrame:frm];
    frm = [[cell textLabel] frame];
    frm.size.height = 24;
    [[cell textLabel] setFrame:frm];
    UIFont* fnt = [[cell textLabel] font];
    [[cell textLabel] setFont:[UIFont fontWithName:[fnt fontName] size:14]];
    [[cell textLabel] setText:[[fields objectAtIndex:[indexPath row]] description]];
    if ([FieldName isEqualToString:[[fields objectAtIndex:[indexPath row]] description]])
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FieldName = [[fields objectAtIndex:[indexPath row]] description];
}


-(BOOL)shouldPerformSegueWithIdentifier:(NSString*)id sender:(id)sender {
    BOOL nonempty = ([FieldName length] > 0 &&
                [[textUnit text] length] > 0 &&
                [[textFuelTruckOperator text] length] > 0);
    BOOL valid = ([Data isNumber:[textFuelTruckOperator text]] &&
                  [Data isNumber:[textOperator text]] &&
                  [Data isNumber:[textUnit text]]);

    NSString* title = [switchLanguage isOn] ? @"Información Inválida" : @"Invalid Information";
    NSString* msg = nil;
    if (!nonempty)
        msg = [switchLanguage isOn] ?
                @"Necesario: Campo, Operador de Combustible #, Unidad #" :
                @"Required: Field, Fuel Truck Operator#, Unit #";
    else if (!valid)
        msg = [switchLanguage isOn] ?
        @"Operador de Combustible #, Operador #, y Unidad # debe ser un número" :
        @"Fuel Truck Operator #, Operator # and Unit # must be a number";
    
    if (msg != nil) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        FuelTruckOperatorID = [textFuelTruckOperator text];
        UnitID = [textUnit text];
        ImplementID = [textImplement text];
        OperatorID = [textOperator text];
    }
    
    return (nonempty && valid);
}

-(IBAction)reset:(id)sender {
    FieldName = @"";
    UnitID = @"";
    ImplementID = @"";
    OperatorID = @"";
    
    UnitHours = @"";
    Reminders = @"";
    GallonsDiesel = @"";
    GallonsDEF = @"";
    Timestamp = @"";
    MotorOil = NO;
    HydraulicOil = NO;
    Inspection = NO;
    
    [textUnit setText:@""];
    [textImplement setText:@""];
    [textOperator setText:@""];
}

-(IBAction)submitStartMeterToServer:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Start Meter"
                                                    message:@"What is the start meter reading?"
                                                   delegate:self
                                          cancelButtonTitle:@"Done"
                                          otherButtonTitles:@"Cancel", nil];
    [alert setTag:1];
    [alert setAlertViewStyle: UIAlertViewStylePlainTextInput];
    [alert show];
}

-(IBAction)submitEndMeterToServer:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"End Meter"
                                                    message:@"What is the end meter reading?"
                                                   delegate:self
                                          cancelButtonTitle:@"Done"
                                          otherButtonTitles:@"Cancel", nil];
    [alert setTag:2];
    [alert setAlertViewStyle: UIAlertViewStylePlainTextInput];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"%@", [alertView textFieldAtIndex:0].text);
    
    if (buttonIndex == 0 && [[[alertView textFieldAtIndex:0] text] length] > 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSString* ts = [dateFormatter stringFromDate:[NSDate date]];
    
        NSString* body = ([alertView tag] == 1) ?
                            [NSString stringWithFormat:@"TruckID=1&StartMeter=%@&Day=%@",
                             [alertView textFieldAtIndex:0].text, ts] :
                            [NSString stringWithFormat:@"TruckID=1&EndMeter=%@&Day=%@",
                             [alertView textFieldAtIndex:0].text, ts];
    
        if (conn == nil)
            conn = [[Submit alloc] init];
        [conn submitToServerWithBody:body onComplete:^(BOOL s, NSString* m) {
            [self submitComplete:s withMessage:m];
        }];
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
    
    [btnSync setEnabled:NO];
    if (conn == nil)
        conn = [[Submit alloc] init];
    for (NSString* body in resends) {
        [conn submitToServerWithBody:body onComplete:^(BOOL s, NSString* m) {
            [self submitComplete:s withMessage:m];
        }];
    }
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
    [btnSync setEnabled:YES];
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

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    //Don't allow it to re-sort the fields if we're currently re-sorting fields
    locationErrorAlert = 0;
    [lblLatitude setText:[NSString stringWithFormat:@"(%d) lat: %f",
                          cLocations, [[self currentLoc] coordinate].latitude]];
    [lblLongitude setText:[NSString stringWithFormat:@"(%d) long: %f",
                           cLocations, [[self currentLoc] coordinate].longitude]];
    if (!isSorting && [locations count] > 0) {
        cLocations = (cLocations+1) % 1000;
        CLLocation* loc = [locations objectAtIndex:[locations count] - 1];
        
        [lblLatitude setText:[NSString stringWithFormat:@"(%d) lat: %f",
                              cLocations, [loc coordinate].latitude]];
        [lblLongitude setText:[NSString stringWithFormat:@"(%d) long: %f",
                               cLocations, [loc coordinate].longitude]];
        
        if ([loc coordinate].latitude > latMin && [loc coordinate].longitude > longMin &&
            [loc coordinate].latitude < latMax && [loc coordinate].longitude < longMax) {
            
            if ([[self currentLoc] coordinate].latitude != [loc coordinate].latitude ||
                [[self currentLoc] coordinate].longitude != [loc coordinate].longitude) {
                [self setCurrentLoc:loc];

                [self orderFields];
                [tableFields reloadData];
            }
        }
    }
}

-(void) orderFields {
    isSorting = true;
    fields = [fields sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        double d1 = [self distanceToField:obj1];
        double d2 = [self distanceToField:obj2];
        
        if (d1 < d2) return NSOrderedAscending;
        else if (d1 > d2) return NSOrderedDescending;
        else return NSOrderedSame;
    }];
    isSorting = false;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"Couldn't find GPS: %@ (%@). We'll keep trying",
                     [error localizedDescription], [error localizedFailureReason]];
    if ([error code] == kCLErrorDenied)
        [[self locationManager] stopUpdatingLocation];
    else if (locationErrorAlert == 5) {
        locationErrorAlert++;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
        locationErrorAlert++;
}

-(double)distanceToField:(Field*)f {
    double latField = [f latitude], lonField = [f longitude];
    double latCur = [[self currentLoc] coordinate].latitude,
            longCur = [[self currentLoc] coordinate].longitude;
    const double ratio = 3.1415926 / 180.0;
    double latFieldInRad = latField * ratio;
    double longFieldInRad = lonField * ratio;
    double latCurInRad = latCur * ratio;
    double longCurInRad = longCur * ratio;
    
    double dLongitude = longCurInRad - longFieldInRad;
    double dLatitude = latCurInRad - latFieldInRad;
    
    // Intermediate result a.
    double a = sin(dLatitude / 2.0) * sin(dLatitude / 2.0) +
        cos(latFieldInRad) * cos(latCurInRad) *
        sin(dLongitude / 2.0) * sin(dLongitude / 2.0);
    
    // Intermediate result c (great circle distance in Radians).
    double c = 2.0 * asin(sqrt(a));
    
    // Distance.
    // const Double kEarthRadiusMiles = 3956.0;
    const double kEarthRadiusKms = 6376.5;
    double dDistance = kEarthRadiusKms * c;
    
    return dDistance;
}

-(void)goEnglish {
    if (lblFuelTruckOperator != nil)
        [lblFuelTruckOperator setText:@"Fuel Truck Operator #:"];
    else
        [textFuelTruckOperator setPlaceholder:@"Fuel Truck Op. #"];
    [lblField setText:@"Field:"];
    if (lblUnit != nil)
        [lblUnit setText:@"Unit #:"];
    else
        [textUnit setPlaceholder:@"Unit #"];
    if (lblOperator != nil)
        [lblOperator setText:@"Operator #:"];
    else
        [textOperator setPlaceholder:@"Operator #"];
    if (lblImplement != nil)
        [lblImplement setText:@"Implement:"];
    else
        [textImplement setPlaceholder:@"Implement"];
    
    [btnReset setTitle:@"reset" forState:UIControlStateNormal];
    [btnNext setTitle:@"next" forState:UIControlStateNormal];
}

-(void)goSpanish {
    if (lblFuelTruckOperator != nil)
        [lblFuelTruckOperator setText:@"Operador de Combustible #:"];
    else
        [textFuelTruckOperator setPlaceholder:@"Oper de Combust #"];
    [lblField setText:@"Campo:"];
    if (lblUnit != nil)
        [lblUnit setText:@"Unidad #:"];
    else
        [textUnit setPlaceholder:@"Unidad #"];
    if (lblOperator != nil)
        [lblOperator setText:@"Operador #:"];
    else
        [textOperator setPlaceholder:@"Operador #"];
    if (lblImplement != nil)
        [lblImplement setText:@"Implemento:"];
    else
        [textImplement setPlaceholder:@"Implemento"];
    
    [btnReset setTitle:@"restaurar" forState:UIControlStateNormal];
    [btnNext setTitle:@"proximo" forState:UIControlStateNormal];
}

-(void)loadFields {
    [self loadFieldsStatic];
    [self loadFieldsFromServer];
    
    
    latMin = longMin = MAXFLOAT;
    latMax = longMax = 0;
    
    for (Field*f in fields) {
        if (latMin > [f latitude]) latMin = [f latitude];
        if (longMin > [f longitude]) longMin = [f longitude];
        if (latMax < [f latitude]) latMax = [f latitude];
        if (longMax < [f longitude]) longMax = [f longitude];
    }
    
    latMin -= 1; longMin -= 1;
    latMax += 1; longMax += 1;
}

-(void)loadFieldsFromServer {
    NSString* surl = [NSString stringWithFormat:@"http://www.mercerdata.com/fields.php?farmid=%d", FarmID];
    NSURL* url = [NSURL URLWithString:surl];
    NSURLRequest* req = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    inetdata = [[NSMutableData alloc] init];
    NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:req
                                                            delegate:self
                                                    startImmediately:YES];
}

-(void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    [inetdata appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection*) conn {
    //Now that we have data from the server, re-initialize fields to an empty array
    fieldsStore = [[NSMutableArray alloc] init];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inetdata];
    [parser setDelegate:self];
    [parser parse];
    
    fields = [NSArray arrayWithArray:fieldsStore];
    [self orderFields];
    [tableFields reloadData];
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"f"]) {
        Field* fld = [[Field alloc] initWithName:[attributeDict objectForKey:@"name"]
                                        latitude:[[attributeDict objectForKey:@"lat"] doubleValue]
                                       longitude:[[attributeDict objectForKey:@"long"] doubleValue]];
        [fieldsStore addObject:fld];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
}

-(void) loadFieldsStatic {
    NSMutableArray* loadedFields = [[NSMutableArray alloc] init];
    
    [loadedFields addObject:[[Field alloc] initWithName:@"10" latitude:45.8879544372 longitude:-119.91166234]];
    [loadedFields addObject:[[Field alloc] initWithName:@"11" latitude:45.883875802 longitude:-119.862381007]];
    [loadedFields addObject:[[Field alloc] initWithName:@"110" latitude:45.9441838 longitude:-119.8956177]];
    [loadedFields addObject:[[Field alloc] initWithName:@"111" latitude:45.9494398 longitude:-119.8950321]];
    [loadedFields addObject:[[Field alloc] initWithName:@"112" latitude:45.9462508 longitude:-119.8901687]];
    [loadedFields addObject:[[Field alloc] initWithName:@"113" latitude:45.9505267 longitude:-119.8711014]];
    [loadedFields addObject:[[Field alloc] initWithName:@"114" latitude:45.9475471 longitude:-119.8689235]];
    [loadedFields addObject:[[Field alloc] initWithName:@"115" latitude:45.9363832 longitude:-119.8752814]];
    [loadedFields addObject:[[Field alloc] initWithName:@"116" latitude:45.9399023 longitude:-119.8736857]];
    [loadedFields addObject:[[Field alloc] initWithName:@"117" latitude:45.9364249 longitude:-119.8687103]];
    [loadedFields addObject:[[Field alloc] initWithName:@"11SW" latitude:45.8816885248 longitude:-119.865968227]];
    [loadedFields addObject:[[Field alloc] initWithName:@"12" latitude:45.8911431015 longitude:-119.862319806]];
    [loadedFields addObject:[[Field alloc] initWithName:@"13" latitude:45.869856593 longitude:-119.877925579]];
    [loadedFields addObject:[[Field alloc] initWithName:@"14" latitude:45.8802870015 longitude:-119.852501204]];
    [loadedFields addObject:[[Field alloc] initWithName:@"15" latitude:45.8873793563 longitude:-119.853207293]];
    [loadedFields addObject:[[Field alloc] initWithName:@"16" latitude:45.894821503 longitude:-119.853314606]];
    [loadedFields addObject:[[Field alloc] initWithName:@"17" latitude:45.8840055025 longitude:-119.842762802]];
    [loadedFields addObject:[[Field alloc] initWithName:@"18" latitude:45.8912546035 longitude:-119.844021004]];
    [loadedFields addObject:[[Field alloc] initWithName:@"18NE" latitude:45.8957355406 longitude:-119.840326309]];
    [loadedFields addObject:[[Field alloc] initWithName:@"19" latitude:45.8882785045 longitude:-119.834970607]];
    [loadedFields addObject:[[Field alloc] initWithName:@"1N" latitude:45.8773569015 longitude:-119.861698006]];
    [loadedFields addObject:[[Field alloc] initWithName:@"1S" latitude:45.8744731574936 longitude:-119.861398667357]];
    [loadedFields addObject:[[Field alloc] initWithName:@"2" latitude:45.8764047985 longitude:-119.872803202]];
    [loadedFields addObject:[[Field alloc] initWithName:@"20" latitude:45.894942504 longitude:-119.835255407]];
    [loadedFields addObject:[[Field alloc] initWithName:@"20NE" latitude:45.8967062344847 longitude:-119.829844236373]];
    [loadedFields addObject:[[Field alloc] initWithName:@"21" latitude:45.869326701 longitude:-119.893658808]];
    [loadedFields addObject:[[Field alloc] initWithName:@"22" latitude:45.8693702015 longitude:-119.9037643]];
    [loadedFields addObject:[[Field alloc] initWithName:@"23" latitude:45.8838859035 longitude:-119.872801904999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"23SW" latitude:45.8811059673437 longitude:-119.878494143486]];
    [loadedFields addObject:[[Field alloc] initWithName:@"24" latitude:45.8911527025 longitude:-119.8727355035]];
    [loadedFields addObject:[[Field alloc] initWithName:@"25" latitude:45.898433006 longitude:-119.8726587075]];
    [loadedFields addObject:[[Field alloc] initWithName:@"25NE" latitude:45.9005664336314 longitude:-119.868645071983]];
    [loadedFields addObject:[[Field alloc] initWithName:@"26" latitude:45.8875347034999 longitude:-119.8675799025]];
    [loadedFields addObject:[[Field alloc] initWithName:@"27" latitude:45.8911965015 longitude:-119.883196402]];
    [loadedFields addObject:[[Field alloc] initWithName:@"28" latitude:45.8984989024999 longitude:-119.883165907]];
    [loadedFields addObject:[[Field alloc] initWithName:@"28NE" latitude:45.9013018684468 longitude:-119.877877462452]];
    [loadedFields addObject:[[Field alloc] initWithName:@"29" latitude:45.887529902 longitude:-119.8884410095]];
    [loadedFields addObject:[[Field alloc] initWithName:@"3" latitude:45.8763508 longitude:-119.883205403]];
    [loadedFields addObject:[[Field alloc] initWithName:@"30" latitude:45.8874991029999 longitude:-119.8780063025]];
    [loadedFields addObject:[[Field alloc] initWithName:@"31" latitude:45.8985580039999 longitude:-119.893640205499]];
    [loadedFields addObject:[[Field alloc] initWithName:@"31NW" latitude:45.9018207341126 longitude:-119.897768497467]];
    [loadedFields addObject:[[Field alloc] initWithName:@"32" latitude:45.876468101 longitude:-119.893675803]];
    [loadedFields addObject:[[Field alloc] initWithName:@"32NE" latitude:45.8785590093178 longitude:-119.890333414078]];
    [loadedFields addObject:[[Field alloc] initWithName:@"33" latitude:45.8948397025 longitude:-119.888466305]];
    [loadedFields addObject:[[Field alloc] initWithName:@"34" latitude:45.8948199 longitude:-119.877925806]];
    [loadedFields addObject:[[Field alloc] initWithName:@"35" latitude:45.8975599065 longitude:-119.861674607]];
    [loadedFields addObject:[[Field alloc] initWithName:@"36" latitude:45.9051511 longitude:-119.8945923065]];
    [loadedFields addObject:[[Field alloc] initWithName:@"36NE" latitude:45.9064121969331 longitude:-119.890848398208]];
    [loadedFields addObject:[[Field alloc] initWithName:@"37" latitude:45.878546702 longitude:-119.8454324045]];
    [loadedFields addObject:[[Field alloc] initWithName:@"38" latitude:45.8952250025 longitude:-119.866820305]];
    [loadedFields addObject:[[Field alloc] initWithName:@"39" latitude:45.9028679034999 longitude:-119.8883774065]];
    [loadedFields addObject:[[Field alloc] initWithName:@"4" latitude:45.8838095226416 longitude:-119.88327969982]];
    [loadedFields addObject:[[Field alloc] initWithName:@"40" latitude:45.920139360131 longitude:-119.855007499105]];
    [loadedFields addObject:[[Field alloc] initWithName:@"41" latitude:45.912794717707 longitude:-119.86232046746]];
    [loadedFields addObject:[[Field alloc] initWithName:@"42" latitude:45.9126186065 longitude:-119.8520888015]];
    [loadedFields addObject:[[Field alloc] initWithName:@"43" latitude:45.9125142005 longitude:-119.841819504999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"44" latitude:45.9051802693361 longitude:-119.861785455321]];
    [loadedFields addObject:[[Field alloc] initWithName:@"45" latitude:45.9057901045 longitude:-119.8515164045]];
    [loadedFields addObject:[[Field alloc] initWithName:@"46" latitude:45.9056138054999 longitude:-119.842152108]];
    [loadedFields addObject:[[Field alloc] initWithName:@"47" latitude:45.917109177646 longitude:-119.846942820392]];
    [loadedFields addObject:[[Field alloc] initWithName:@"48" latitude:45.9087636639278 longitude:-119.832655098036]];
    [loadedFields addObject:[[Field alloc] initWithName:@"49" latitude:45.903320302 longitude:-119.828871298]];
    [loadedFields addObject:[[Field alloc] initWithName:@"5" latitude:45.8839727059999 longitude:-119.8936474035]];
    [loadedFields addObject:[[Field alloc] initWithName:@"50" latitude:45.9249707 longitude:-119.8608408005]];
    [loadedFields addObject:[[Field alloc] initWithName:@"51" latitude:45.9261286025 longitude:-119.886331439]];
    [loadedFields addObject:[[Field alloc] initWithName:@"52" latitude:45.907882863425 longitude:-119.824693586624]];
    [loadedFields addObject:[[Field alloc] initWithName:@"53" latitude:45.8891919059999 longitude:-119.829237505]];
    [loadedFields addObject:[[Field alloc] initWithName:@"56" latitude:45.9254906802579 longitude:-119.897404392705]];
    [loadedFields addObject:[[Field alloc] initWithName:@"58" latitude:45.8728372960939 longitude:-119.889571780851]];
    [loadedFields addObject:[[Field alloc] initWithName:@"59" latitude:45.8700207045 longitude:-119.885786306]];
    [loadedFields addObject:[[Field alloc] initWithName:@"5NW" latitude:45.8876056044999 longitude:-119.897677303]];
    [loadedFields addObject:[[Field alloc] initWithName:@"6" latitude:45.8912518035 longitude:-119.893647602]];
    [loadedFields addObject:[[Field alloc] initWithName:@"61" latitude:45.8984809015 longitude:-119.924814004]];
    [loadedFields addObject:[[Field alloc] initWithName:@"63" latitude:45.891960702 longitude:-119.9186761005]];
    [loadedFields addObject:[[Field alloc] initWithName:@"64" latitude:45.9071943044999 longitude:-119.916804205]];
    [loadedFields addObject:[[Field alloc] initWithName:@"66" latitude:45.9366092892418 longitude:-119.879919062273]];
    [loadedFields addObject:[[Field alloc] initWithName:@"67" latitude:45.932341182615 longitude:-119.876717532203]];
    [loadedFields addObject:[[Field alloc] initWithName:@"68" latitude:45.9329978496339 longitude:-119.87080852217]];
    [loadedFields addObject:[[Field alloc] initWithName:@"69" latitude:45.9182638015 longitude:-119.900265005]];
    [loadedFields addObject:[[Field alloc] initWithName:@"6NW" latitude:45.8876333687971 longitude:-119.89768814594]];
    [loadedFields addObject:[[Field alloc] initWithName:@"7" latitude:45.8821216173354 longitude:-119.903907014284]];
    [loadedFields addObject:[[Field alloc] initWithName:@"70" latitude:45.9138590045 longitude:-119.893634103]];
    [loadedFields addObject:[[Field alloc] initWithName:@"71" latitude:45.9212609045 longitude:-119.8937009025]];
    [loadedFields addObject:[[Field alloc] initWithName:@"73" latitude:45.9266324694235 longitude:-119.891439226858]];
    [loadedFields addObject:[[Field alloc] initWithName:@"74" latitude:45.9272933055 longitude:-119.867871503]];
    [loadedFields addObject:[[Field alloc] initWithName:@"75" latitude:45.9296221034999 longitude:-119.8785726025]];
    [loadedFields addObject:[[Field alloc] initWithName:@"76" latitude:45.9340349675782 longitude:-119.887276286225]];
    [loadedFields addObject:[[Field alloc] initWithName:@"77" latitude:45.932805203 longitude:-119.896951000999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"78" latitude:45.9383849781063 longitude:-119.903722956683]];
    [loadedFields addObject:[[Field alloc] initWithName:@"79" latitude:45.9302741675215 longitude:-119.90597160569]];
    [loadedFields addObject:[[Field alloc] initWithName:@"8" latitude:45.8893359498487 longitude:-119.904045047255]];
    [loadedFields addObject:[[Field alloc] initWithName:@"80" latitude:45.942540003 longitude:-119.877611403999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"81" latitude:45.941886704 longitude:-119.8863597045]];
    [loadedFields addObject:[[Field alloc] initWithName:@"82" latitude:45.946691403 longitude:-119.8839221015]];
    [loadedFields addObject:[[Field alloc] initWithName:@"83" latitude:45.8968591 longitude:-119.845079599999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"84" latitude:45.8988193084871 longitude:-119.855046272278]];
    [loadedFields addObject:[[Field alloc] initWithName:@"85" latitude:45.8980950312565 longitude:-119.849907159805]];
    [loadedFields addObject:[[Field alloc] initWithName:@"86" latitude:45.9099059497447 longitude:-119.857344088162]];
    [loadedFields addObject:[[Field alloc] initWithName:@"87" latitude:45.9083121491542 longitude:-119.856247957505]];
    [loadedFields addObject:[[Field alloc] initWithName:@"88" latitude:45.8665248129921 longitude:-119.898777273311]];
    [loadedFields addObject:[[Field alloc] initWithName:@"89" latitude:45.874343902 longitude:-119.906252803]];
    [loadedFields addObject:[[Field alloc] initWithName:@"9" latitude:45.8966240114657 longitude:-119.904170968742]];
    [loadedFields addObject:[[Field alloc] initWithName:@"90" latitude:45.9091295710823 longitude:-119.866317042274]];
    [loadedFields addObject:[[Field alloc] initWithName:@"91" latitude:45.8874428 longitude:-119.8592835]];
    [loadedFields addObject:[[Field alloc] initWithName:@"92" latitude:45.8911320999999 longitude:-119.8562579]];
    [loadedFields addObject:[[Field alloc] initWithName:@"93" latitude:45.8878312850608 longitude:-119.840387360291]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Berg103" latitude:46.005661002 longitude:-119.617614906999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Berg104" latitude:46.0165997035 longitude:-119.608433101999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Cal 3" latitude:45.9130634392256 longitude:-119.883069992065]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Cal 4" latitude:45.9202886894777 longitude:-119.883218376997]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Cal 5" latitude:45.9166911791828 longitude:-119.876596247848]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Cal 7" latitude:45.9199901406286 longitude:-119.866125743034]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Cal 8" latitude:45.903937903 longitude:-119.8708787045]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Carma" latitude:46.2199678248145 longitude:-119.724133014679]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1005" latitude:45.9066945 longitude:-119.952006]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1006" latitude:45.9047215 longitude:-119.9476505]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1009" latitude:45.9055769999999 longitude:-119.943852499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1010" latitude:45.9044865 longitude:-119.939452]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1102" latitude:45.903914 longitude:-119.950984]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1103" latitude:45.903619 longitude:-119.9451335]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1107" latitude:45.902805 longitude:-119.940523]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1111" latitude:45.9045665 longitude:-119.934276]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1112" latitude:45.9043335 longitude:-119.933398]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1113" latitude:45.9092395 longitude:-119.9443895]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1114" latitude:45.9081365 longitude:-119.9409745]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CCS1193" latitude:45.902505 longitude:-119.937631]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09CS1" latitude:45.9411916091581 longitude:-119.906866550445]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09CS4" latitude:45.9299213029362 longitude:-119.88931953907]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09CS5" latitude:45.928465389664 longitude:-119.897451996803]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09CS6" latitude:45.929563110913 longitude:-119.901030063629]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09CS7" latitude:45.9347246511488 longitude:-119.907242059707]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09MR2" latitude:45.9395826955387 longitude:-119.897156953812]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CD09VG3" latitude:45.9374472854585 longitude:-119.893503785133]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CMR1008" latitude:45.9079145 longitude:-119.9493875]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CMR1101" latitude:45.906367 longitude:-119.957089]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CMR1104" latitude:45.9079785 longitude:-119.956866999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CMR1215" latitude:45.906879 longitude:-119.935971]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CMR1216" latitude:45.9079225 longitude:-119.9329195]];
    [loadedFields addObject:[[Field alloc] initWithName:@"CTG" latitude:45.903321 longitude:-119.9425505]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP1" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP10" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP11" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP2" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP3" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP4" latitude: longitude:]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"EP5" latitude: longitude:]];
    [loadedFields addObject:[[Field alloc] initWithName:@"EP6" latitude:45.9348376015 longitude:-119.914125103]];
    [loadedFields addObject:[[Field alloc] initWithName:@"EP7" latitude:45.9328858 longitude:-119.9168411025]];
    [loadedFields addObject:[[Field alloc] initWithName:@"EP8" latitude:45.933153503 longitude:-119.911883504999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"EP9" latitude:45.9307121024999 longitude:-119.9118354015]];
    [loadedFields addObject:[[Field alloc] initWithName:@"J10" latitude:45.9377090005 longitude:-119.776585397]];
    [loadedFields addObject:[[Field alloc] initWithName:@"J11" latitude:45.9377475045 longitude:-119.7672848065]];
    [loadedFields addObject:[[Field alloc] initWithName:@"MCR0901" latitude:45.8995630141539 longitude:-119.910385608673]];
    [loadedFields addObject:[[Field alloc] initWithName:@"MCS0003" latitude:45.8794568929627 longitude:-119.897258877754]];
    [loadedFields addObject:[[Field alloc] initWithName:@"MCS1103" latitude:45.8989789515999 longitude:-119.9100664258]];
    [loadedFields addObject:[[Field alloc] initWithName:@"MPV0902" latitude:45.8988705006632 longitude:-119.91156309843]];
    [loadedFields addObject:[[Field alloc] initWithName:@"New Planting 2014 West Princeton" latitude:45.9345824398408 longitude:-119.95379447937]];
    //[loadedFields addObject:[[Field alloc] initWithName:@"North Slope Willis Alford" latitude: longitude:]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PCS1210" latitude:45.9273605 longitude:-119.927835499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1205" latitude:45.920704 longitude:-119.9282195]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1206" latitude:45.9185735 longitude:-119.9252135]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1211" latitude:45.9241475 longitude:-119.927742999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1212" latitude:45.9230975 longitude:-119.925939]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1218" latitude:45.9257395 longitude:-119.922112]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1219" latitude:45.9240715 longitude:-119.9181645]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1220" latitude:45.928177 longitude:-119.921943]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1224" latitude:45.9301445 longitude:-119.9212445]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PMR1325" latitude:45.928853 longitude:-119.918039999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSB1221" latitude:45.9269885 longitude:-119.919147]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1213" latitude:45.9220959999999 longitude:-119.921980999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1214" latitude:45.9201255 longitude:-119.922254]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1215" latitude:45.9210945 longitude:-119.9166035]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1322" latitude:45.924236 longitude:-119.915299]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1323" latitude:45.9226644999999 longitude:-119.911891]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1326" latitude:45.9275894999999 longitude:-119.9153745]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PSY1327" latitude:45.9258145 longitude:-119.9125455]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1201" latitude:45.910174 longitude:-119.9257225]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1202" latitude:45.915098 longitude:-119.9266235]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1203" latitude:45.913436 longitude:-119.9275575]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1204" latitude:45.9128265 longitude:-119.9231315]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1207" latitude:45.9165175 longitude:-119.921652]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1208" latitude:45.9155005 longitude:-119.9170235]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1209" latitude:45.9143179999999 longitude:-119.9125945]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1216" latitude:45.9187415 longitude:-119.9172815]];
    [loadedFields addObject:[[Field alloc] initWithName:@"PWR1217" latitude:45.9184915 longitude:-119.91178]];
    [loadedFields addObject:[[Field alloc] initWithName:@"Roadside" latitude:45.9074334439834 longitude:-119.883670806885]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SBM1112" latitude:45.8746945450398 longitude:-119.831756651401]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCE1121" latitude:45.883441 longitude:-119.823197499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCG1224" latitude:45.8829345 longitude:-119.823242]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCS0707" latitude:45.8735119158726 longitude:-119.829205870628]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCS1225" latitude:45.8825185 longitude:-119.823222]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCS1327" latitude:45.880379 longitude:-119.824639499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SCT1123" latitude:45.8831195 longitude:-119.823233]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SGR0503" latitude:45.8763266561767 longitude:-119.829457998276]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SGR1120" latitude:45.884355 longitude:-119.822894499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SM104" latitude:45.9464809035 longitude:-119.627358807]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SM106" latitude:45.945259905 longitude:-119.637095506]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SM112" latitude:45.9377284001143 longitude:-119.66863704475]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SM130" latitude:45.9486428005 longitude:-119.648961902]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMA0606" latitude:45.8744405734983 longitude:-119.829723536968]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMA0908" latitude:45.8734338580078 longitude:-119.832403063774]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMA0909" latitude:45.8740609024647 longitude:-119.831798225641]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMA0910" latitude:45.8728924417511 longitude:-119.831413328647]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMR1313" latitude:45.8725923721998 longitude:-119.82849240303]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMR1328" latitude:45.8792035 longitude:-119.825167999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SMV0605" latitude:45.8746013601605 longitude:-119.829573333263]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SPS0604" latitude:45.8748644809653 longitude:-119.829326570034]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SPV0501" latitude:45.8777142883946 longitude:-119.827829897403]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SSN0502" latitude:45.8770513822748 longitude:-119.82832878828]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SSY1111" latitude:45.8736381645355 longitude:-119.831480383873]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SSY1122" latitude:45.883309 longitude:-119.823259]];
    [loadedFields addObject:[[Field alloc] initWithName:@"SSY1326" latitude:45.881477 longitude:-119.823788]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1301" latitude:45.954882 longitude:-119.9471295]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1302" latitude:45.952366 longitude:-119.942136]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1303" latitude:45.9505374999999 longitude:-119.938293]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1304" latitude:45.9488455 longitude:-119.9336925]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1305" latitude:45.952726 longitude:-119.9476525]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1306" latitude:45.9508065 longitude:-119.942715499999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1307" latitude:45.95012 longitude:-119.9471925]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1308" latitude:45.9483199999999 longitude:-119.942056]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1309" latitude:45.9461915 longitude:-119.9367135]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1310" latitude:45.946663 longitude:-119.9470565]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1311" latitude:45.9451114999999 longitude:-119.940814999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1312" latitude:45.9425945 longitude:-119.937063999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1313" latitude:45.9436595 longitude:-119.943251]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1314" latitude:45.9417514999999 longitude:-119.939392]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1315" latitude:45.9434875 longitude:-119.9476485]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1316" latitude:45.940382 longitude:-119.9477545]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1317" latitude:45.940231 longitude:-119.945112999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WCS1318" latitude:45.9395614999999 longitude:-119.940193999999]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WMR1320" latitude:45.9407745 longitude:-119.9314055]];
    [loadedFields addObject:[[Field alloc] initWithName:@"WSY1319" latitude:45.940021 longitude:-119.933475]];
    
    fields = [NSArray arrayWithArray:loadedFields];
}

@end
