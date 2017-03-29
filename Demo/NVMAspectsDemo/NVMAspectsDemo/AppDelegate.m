//
//  AppDelegate.m
//  NVMAspectsDemo
//
//  Created by Karl Peng on 03/28/2017.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "AppDelegate.h"
@import NVMAspects;

@interface AppDelegate ()

@end

@interface AppDelegate (NotImp)

- (void)notImp;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [[self class] nvm_hookSelector:@selector(emptyMethod)
                      usingBlock:^(NVMAspectInfo *info) {
                        [info.oriInvocation invoke];
                        NSLog(@"Hooked Empty");
                      } error:NULL];
  
  [[self class] nvm_hookSelector:@selector(emptyMethod)
                      usingBlock:^(NVMAspectInfo *info) {
                        [info.oriInvocation invoke];
                        NSLog(@"Hooked Empty again");
                      } error:NULL];
  
  NSObject *object = [NSObject new];
  [[self class] nvm_hookSelector:@selector(methodReturnObject) usingBlock:^(NVMAspectInfo *info){
    return object;
  } error:NULL];
  
  [[self class] nvm_hookSelector:@selector(methodReturnInt)
                      usingBlock:^NSInteger (NVMAspectInfo *info){
                        return 2;
                      } error:NULL];
  [[self class] nvm_hookSelector:@selector(notImp)
                      usingBlock:^(NVMAspectInfo *info){
                        NSLog(@"Hook not imp");
                      } error:NULL];
  
  [self emptyMethod];
  
  NSObject *returnObject = [self methodReturnObject];
  NSAssert(returnObject == object, nil);
  
  NSAssert([self methodReturnInt] == 2, nil);
  
  [self notImp];
  
  return YES;
}

- (void)emptyMethod {
  NSLog(@"emptyMethod");
}

- (id)methodReturnObject {
  NSLog(@"methodReturnObject");
  return [NSObject new];
}

- (NSInteger)methodReturnInt {
  return 1;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
