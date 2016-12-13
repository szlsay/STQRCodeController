//
//  AppDelegate.m
//  STQRCodeControllerDemo
//
//  Created by ST on 16/11/29.
//  Copyright © 2016年 ST. All rights reserved.
//

#import "AppDelegate.h"
#import "TestController.h"

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[TestController alloc]init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
