//
//  AppDelegate.m
//  NVMAspectsDemo
//
//  Created by Karl Peng on 03/28/2017.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "AppDelegate.h"
@import NVMAspects;

typedef struct _ComplexStruct {
  int a;
  double b;
  CGRect c;
  CFTypeRef d;
} ComplexStruct;

@interface AppDelegate ()

@end

typedef void(^ReturnedBlock)(void);

@interface AppDelegate (NotImp)

- (void)methodWithoutImplement;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self nvm_hookInstanceMethod:@selector(methodReturnVoid)
                    usingBlock:^(NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodReturnVoid");
                    } error:NULL];

  [self nvm_hookInstanceMethod:@selector(methodReturnVoid)
                    usingBlock:^(NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodReturnVoid again");
                    } error:NULL];
  
  NSObject *object = [NSObject new];
  [self nvm_hookInstanceMethod:@selector(methodReturnHookedObject)
                    usingBlock:^(NVMAspectInfo *info){
                      NSLog(@"Hooked methodReturnObject");
                      return object;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodReturnORIObject)
                    usingBlock:^id(NVMAspectInfo *info) {
                      NSLog(@"Hooked methodReturnORIObject");
                      [info.oriInvocation invoke];
                      void *returnValue = NULL;
                      [info.oriInvocation getReturnValue:&returnValue];
                      return (__bridge id) returnValue;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnInt)
                    usingBlock:^NSInteger (NVMAspectInfo *info){
                      NSLog(@"Hooked methodReturnInt");
                      return 2;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodWithoutImplement)
                    usingBlock:^(NVMAspectInfo *info){
                      NSLog(@"%@", info.slf);
                      NSLog(@"Hooked methodWithoutImplement");
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnArray)
                    usingBlock:^NSArray *(void) {
                      NSLog(@"Hooked methodReturnArray");
                      return nil;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnBlock)
                    usingBlock:^ReturnedBlock (NVMAspectInfo *info) {
                      NSLog(@"Hooked methodReturnBlock");
                      return nil;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnRect)
                    usingBlock:^CGRect(NVMAspectInfo *info){
                      NSLog(@"Hooked methodReturnRect");
                      [info.oriInvocation invoke];
                      CGRect rect;
                      [info.oriInvocation getReturnValue:&rect];
                      return rect;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodHandleComplexStruct:)
                    usingBlock:^ComplexStruct (NVMAspectInfo *info, ComplexStruct cStruct) {
                      NSLog(@"Hooked methodHandleComplexStruct:");
                      return cStruct;
                    } error:NULL];
  
  [self methodReturnVoid];
  
  NSObject *returnObject = [self methodReturnHookedObject];
  NSAssert(returnObject == object, nil);
  
  NSAssert([self methodReturnInt] == 2, nil);
  
  [self methodWithoutImplement];
  
  [self methodReturnRect];
  
  [self methodReturnBlock];
  
  [self methodReturnORIObject];
  
  [self methodReturnArray];
  
  [self methodReturnBlock];
  
  ComplexStruct cStruct;
  [self methodHandleComplexStruct:cStruct];
  
  return YES;
}

- (ReturnedBlock)methodReturnBlock {
  NSLog(@"methodReturnBlock");
  return nil;
}

- (NSArray *)methodReturnArray {
  NSLog(@"methodReturnArray");
  return nil;
}

- (void)methodReturnVoid {
  NSLog(@"ORI methodReturnVoid");
}

- (id)methodReturnHookedObject {
  NSLog(@"ORI methodReturnHookedObject");
  return [NSObject new];
}

- (id)methodReturnORIObject {
  NSLog(@"ORI methodReturnORIObject");
  return [NSObject new];
}

- (NSInteger)methodReturnInt {
  NSLog(@"ORI methodReturnInt");
  return 1;
}

- (CGRect)methodReturnRect {
  NSLog(@"ORI methodReturnRect");
  return CGRectMake(random(), random(), random(), random());
}

- (ComplexStruct)methodHandleComplexStruct:(ComplexStruct)cStruct {
  NSLog(@"ORI methodHandleComplexStruct");
  return cStruct;
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
