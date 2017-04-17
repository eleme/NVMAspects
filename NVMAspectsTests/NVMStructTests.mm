//
//  NVMStructTests.m
//  NVMAspects
//
//  Created by Karl on 16/04/2017.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NVMAspects.h"

#pragma mark - struct define

typedef struct _SimpleStruct {
  char a;
  char b;
  char c;
  char d;
} SimpleStruct, *SimpleStructRef;

BOOL SimpleStructEqualToSimpleStruct(SimpleStruct one,
                                     SimpleStruct theOther) {
  return one.a == theOther.a && one.b == theOther.b;
}

typedef struct _ComplexStruct {
  int a;
  double b;
  CGRect c;
  CFTypeRef d;
} ComplexStruct;

BOOL ComplexStructEqualToComplexStruct(ComplexStruct one,
                                       ComplexStruct theOther) {
  return (one.a == theOther.a &&
          !(one.b != theOther.b) &&
          CGRectEqualToRect(one.c, theOther.c) &&
          one.d == theOther.d);
}

typedef struct _StructWithCArray {
  char a[3];
  char b;
} StructWithCArray;

BOOL StructWithCArrayEqualToStructWithCArray(StructWithCArray one,
                                             StructWithCArray theOther) {
  for (NSInteger i = 0; i < 2; i++) {
    if (one.a[i] != theOther.a[i]) {
      return NO;
    }
  }
  if (one.b != theOther.b) {
    return NO;
  }
  
  return YES;
}

#pragma mark - InOut

static CGRect InRect = CGRectMake(1, 2, 3, 4);
static CGRect OutRect = CGRectMake(3, 1, 2, 2);

static CGPoint InPoint = CGPointMake(1.2, 1.3);
static CGPoint OutPoint = CGPointMake(1.3, 1.4);

static SimpleStruct InSimpleStruct = {.a = 1, .b = 2};
static SimpleStruct OutSimpleStruct = {.a = 3, .b = 4};

static ComplexStruct InComplexStruct = {.a = 1, .b = 1.1, .c = InRect, NULL};
static ComplexStruct OutComplexStruct = {.a = 2, .b = 2.2, .c = OutRect, NULL};

static SimpleStructRef InSimpleStructRef = &InSimpleStruct;
static SimpleStructRef OutSimpleStructRef = &OutSimpleStruct;

static StructWithCArray InStructWithCArray = {.a = {1, 2}, .b = 2};
static StructWithCArray OutStructWithCArray = {.a = {2, 3}, .b = 3};

@interface NVMObjectHandleStruct : NSObject

@end

@implementation NVMObjectHandleStruct

- (CGRect)rectForObject:(id)object withRect:(CGRect)inRect {
  return OutRect;
}

- (CGPoint)pointForObject:(id)object withPoint:(CGPoint)inPoint {
  return OutPoint;
}

- (SimpleStruct)simpleStructForObject:(id)object
                     withSimpleStruct:(SimpleStruct)inSimpleStruct {
  return OutSimpleStruct;
}

- (ComplexStruct)complexStructForObject:(id)object
                      withComplexStruct:(ComplexStruct)inComplexStruct {
  return OutComplexStruct;
}

- (SimpleStructRef)methodHandleStructRef:(SimpleStructRef)inStructRef {
  return OutSimpleStructRef;
}

- (StructWithCArray)methodHandleStructWithCArray:(StructWithCArray)inStructWithCArray {
  return OutStructWithCArray;
}

@end

@interface NVMStructTests : XCTestCase

@property (nonatomic) NVMObjectHandleStruct *targetObject;

@end

@implementation NVMStructTests

- (void)setUp {
    [super setUp];
  self.targetObject = [NVMObjectHandleStruct new];
}

- (void)testRect {
  [self.targetObject nvm_hookInstanceMethod:@selector(rectForObject:withRect:)
                                 usingBlock:^CGRect (NVMAspectInfo *info, id object, CGRect inRect) {
                                   XCTAssert(CGRectEqualToRect(inRect, InRect));
                                   
                                   CGRect temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:3];
                                   XCTAssert(CGRectEqualToRect(inRect, temp));
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(CGRectEqualToRect(OutRect, temp));
                                
                                   return OutRect;
                                 } error:NULL];
  CGRect result = [self.targetObject rectForObject:nil withRect:InRect];
  XCTAssert(CGRectEqualToRect(OutRect, result));
}

- (void)testPoint {
  [self.targetObject nvm_hookInstanceMethod:@selector(pointForObject:withPoint:)
                                 usingBlock:^CGPoint (NVMAspectInfo *info, id object, CGPoint inPoint) {
                                   XCTAssert(CGPointEqualToPoint(inPoint, InPoint));
                    
                                   CGPoint temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:3];
                                   XCTAssert(CGPointEqualToPoint(InPoint, temp));
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(CGPointEqualToPoint(OutPoint, temp));
                                   
                                   return OutPoint;
                                 } error:NULL];
  CGPoint result = [self.targetObject pointForObject:nil withPoint:InPoint];
  XCTAssert(CGPointEqualToPoint(OutPoint, result));
}

- (void)testSimpleStruct {
  [self.targetObject nvm_hookInstanceMethod:@selector(simpleStructForObject:withSimpleStruct:)
                                 usingBlock:^SimpleStruct (NVMAspectInfo *info, id object, SimpleStruct inSimpleStruct) {
                                   XCTAssert(SimpleStructEqualToSimpleStruct(inSimpleStruct, InSimpleStruct));
                                   
                                   SimpleStruct temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:3];
                                   XCTAssert(SimpleStructEqualToSimpleStruct(InSimpleStruct, temp));
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(SimpleStructEqualToSimpleStruct(OutSimpleStruct, temp));
                                   
                                   return OutSimpleStruct;
                                 } error:NULL];
  SimpleStruct result = [self.targetObject simpleStructForObject:nil
                                                withSimpleStruct:InSimpleStruct];
  XCTAssert(SimpleStructEqualToSimpleStruct(OutSimpleStruct, result));
}

- (void)testComplexStruct {
  [self.targetObject nvm_hookInstanceMethod:@selector(complexStructForObject:withComplexStruct:)
                                 usingBlock:^ComplexStruct (NVMAspectInfo *info, id object, ComplexStruct inComplexStruct) {
                                   XCTAssert(ComplexStructEqualToComplexStruct(inComplexStruct, InComplexStruct));
                                   
                                   ComplexStruct temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:3];
                                   XCTAssert(ComplexStructEqualToComplexStruct(InComplexStruct, temp));
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(ComplexStructEqualToComplexStruct(OutComplexStruct, temp));
                                   
                                   return OutComplexStruct;
                                 } error:NULL];
  ComplexStruct result = [self.targetObject complexStructForObject:nil
                                                 withComplexStruct:InComplexStruct];
  XCTAssert(ComplexStructEqualToComplexStruct(OutComplexStruct, result));
}

- (void)testStructRef {
  [self.targetObject nvm_hookInstanceMethod:@selector(methodHandleStructRef:)
                                 usingBlock:^SimpleStructRef (NVMAspectInfo *info, SimpleStructRef inSimpleStructRef) {
                                   XCTAssert(inSimpleStructRef == InSimpleStructRef);
                                   
                                   SimpleStructRef temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:2];
                                   XCTAssert(InSimpleStructRef == temp);
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(OutSimpleStructRef == temp);
                                   
                                   return OutSimpleStructRef;
                                 } error:NULL];
  SimpleStructRef result = [self.targetObject methodHandleStructRef:InSimpleStructRef];
  XCTAssert(result == OutSimpleStructRef);
}

- (void)notestStructWithCArray {
  // struct with c array is not fully support comment out the test
  [self.targetObject nvm_hookInstanceMethod:@selector(methodHandleStructWithCArray:)
                                 usingBlock:^StructWithCArray (NVMAspectInfo *info, StructWithCArray inStructWithCArray) {
                                   XCTAssert(StructWithCArrayEqualToStructWithCArray(inStructWithCArray, InStructWithCArray));
                                   
                                   StructWithCArray temp;
                                   
                                   [info.oriInvocation getArgument:&temp atIndex:2];
                                   XCTAssert(StructWithCArrayEqualToStructWithCArray(temp, inStructWithCArray));
                                   
                                   [info.oriInvocation invoke];
                                   [info.oriInvocation getReturnValue:&temp];
                                   XCTAssert(StructWithCArrayEqualToStructWithCArray(temp, OutStructWithCArray));
                                   
                                   return OutStructWithCArray;
                                 } error:NULL];
  StructWithCArray result = [self.targetObject methodHandleStructWithCArray:InStructWithCArray];
  XCTAssert(StructWithCArrayEqualToStructWithCArray(result, OutStructWithCArray));
}

@end
