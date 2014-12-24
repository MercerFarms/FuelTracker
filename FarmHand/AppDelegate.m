//
//  AppDelegate.m
//  FarmHand
//
//  Created by Peter Tucker on 6/8/14.
//  Copyright (c) 2014 Whitware. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(void)initialize {
    NSString* path = [[NSBundle mainBundle] bundlePath];
    NSString* pListPath = [path stringByAppendingPathComponent:@"Settings.bundle/Root.plist"];
    NSDictionary* pList = [NSDictionary dictionaryWithContentsOfFile:pListPath];
    NSMutableArray* prefsArray = [pList objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary* regDict = [NSMutableDictionary dictionary];
    for (NSDictionary* dict in prefsArray) {
        NSString* key = [dict objectForKey:@"Key"];
        if (key) {
            id value = [dict objectForKey:@"DefaultValue"];
            [regDict setObject:value forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:regDict];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Make sure documents directory exists
    NSString* docdir = [NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager* fmgr = [NSFileManager defaultManager];
    if (![fmgr fileExistsAtPath:docdir]) {
        NSError* err;
        [fmgr createDirectoryAtPath:docdir withIntermediateDirectories:YES attributes:nil error:&err];
        NSLog([err description]);
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
