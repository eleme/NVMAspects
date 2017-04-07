//
//  AppDelegate.m
//  NVMAspectsDemo
//
//  Created by Karl Peng on 03/28/2017.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import <NVMAspects/NVMAspects.h>

typedef struct _ComplexStruct {
  int a;
  double b;
  CGRect c;
  CFTypeRef d;
} ComplexStruct;

typedef struct _SimpleStruct {
  char a;
  char b;
} SimpleStruct;

SimpleStruct MakeSimpleStruct (char a, char b) {
  SimpleStruct s;
  s.a = a;
  s.b = b;
  return s;
}

BOOL EqualToSimpleStruct(SimpleStruct s1, SimpleStruct s2) {
  if (s1.a != s2.a) {
    return NO;
  }
  if (s1.b != s2.b) {
    return NO;
  }
  return YES;
}

ComplexStruct MakeComplexStruct(int a, double b, CGRect c, CFTypeRef d) {
  ComplexStruct s;
  s.a = a;
  s.b = b;
  s.c = c;
  s.d = d;
  
  return s;
}

BOOL EqualToComplexStruct(ComplexStruct s1, ComplexStruct s2) {
  if (s1.a != s2.a) {
    return NO;
  }
  if (s1.b != s2.b) {
    return NO;
  }
  if (!CGRectEqualToRect(s1.c, s2.c)) {
    return NO;
  }
  if (s1.d != s2.d) {
    return NO;
  }
  
  return YES;
}

typedef ComplexStruct * ComplexStructRef;

CGRect RECT = CGRectMake(1, 2, 3, 4);
ComplexStruct COMPLEXSTRUCT = MakeComplexStruct(1, 1.4, RECT, NULL);
SimpleStruct SIMPLESTRUCT = MakeSimpleStruct(1, 2);
CGPoint POINT = CGPointMake(1.4, 1.5);

typedef void(^NormalBlock)(void);

@interface AppDelegate (NoIMP)

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
                      [info.oriInvocation invoke];
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
                    usingBlock:^NSInteger (NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodReturnInt");
                      return 2;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodWithoutImplement)
                    usingBlock:^(NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
                      NSLog(@"%@", info.slf);
                      NSLog(@"Hooked methodWithoutImplement");
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnArray)
                    usingBlock:^NSArray *(NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodReturnArray");
                      return nil;
                    } error:NULL];
  
  [self nvm_hookInstanceMethod:@selector(methodReturnBlock)
                    usingBlock:^NormalBlock (NVMAspectInfo *info) {
                      [info.oriInvocation invoke];
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
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodHandleComplexStruct:");
                      return cStruct;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodWithInt:object:block:)
                    usingBlock:^NormalBlock(NVMAspectInfo *info, NSInteger argInt,
                                            id argObject, NormalBlock argBlock) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodWithMultiArgs");
                      return nil;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodHandleStructRef:)
                    usingBlock:^ComplexStructRef(NVMAspectInfo *info, ComplexStructRef ref) {
                      [info.oriInvocation invoke];
                      NSLog(@"Hooked methodHandleStructRef");
                      return NULL;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodHandleSimpleStruct:)
                    usingBlock:^SimpleStruct(NVMAspectInfo *info, SimpleStruct sStruct) {
                      NSLog(@"Hooked methodHandleSimpleStruct");
                      [info.oriInvocation invoke];
                      return SIMPLESTRUCT;
                    } error:NULL];
  [self nvm_hookInstanceMethod:@selector(methodHandleCGPoint:) usingBlock:^CGPoint (NVMAspectInfo *info, CGPoint point) {
    return POINT;
  } error:NULL];
  
  [self methodReturnVoid];
  
  NSObject *returnObject = [self methodReturnHookedObject];
  NSAssert(returnObject == object, nil);
  
  NSAssert([self methodReturnInt] == 2, nil);
  
  [self methodWithoutImplement];
  
  CGRect returnRect = [self methodReturnRect];
  NSAssert(CGRectEqualToRect(returnRect, RECT), nil);
  
  [self methodReturnBlock];
  
  [self methodReturnORIObject];
  
  [self methodReturnArray];
  
  [self methodReturnBlock];
  
  ComplexStruct cStruct = [self methodHandleComplexStruct:COMPLEXSTRUCT];
  NSAssert(EqualToComplexStruct(cStruct, COMPLEXSTRUCT), nil);
  
  SimpleStruct sStruct = [self methodHandleSimpleStruct:SIMPLESTRUCT];
  NSAssert(EqualToSimpleStruct(sStruct, SIMPLESTRUCT), nil);
  
  CGPoint point = [self methodHandleCGPoint:POINT];
  NSAssert(CGPointEqualToPoint(POINT, point), nil);
  
  [self methodWithInt:1 object:nil block:nil];
  [self methodHandleStructRef:NULL];
  
  return YES;
}

- (NormalBlock)methodReturnBlock {
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

- (NormalBlock)methodWithInt:(NSInteger)argInt object:(id)argObject
                       block:(NormalBlock)argBlock {
  NSLog(@"ORI methodWithMultiArgs");
  return nil;
}

- (CGRect)methodReturnRect {
  NSLog(@"ORI methodReturnRect");
  return RECT;
}


- (ComplexStruct)methodHandleComplexStruct:(ComplexStruct)cStruct {
  NSLog(@"ORI methodHandleComplexStruct");
  return cStruct;
}

- (SimpleStruct)methodHandleSimpleStruct:(SimpleStruct)sStruct {
  NSLog(@"ORI methodHandleSimpleStruct");
  return SIMPLESTRUCT;
}

- (CGPoint)methodHandleCGPoint:(CGPoint)point {
  NSLog(@"ORI methodHandleCGPoint");
  return POINT;
}

- (ComplexStructRef)methodHandleStructRef:(ComplexStructRef)ref {
  NSLog(@"ORI methodHandleStructRef");
  return NULL;
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
