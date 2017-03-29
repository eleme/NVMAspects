//
//  Aspects.m
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "Aspects.h"
#import <objc/runtime.h>
#import <libffi-iOS/ffi.h>
#import "AspectData.h"
#import "Utils.h"

@interface NVMAspectInvocation : NSInvocation

@property (nonatomic, assign) IMP imp;

@end

@interface NVMAspectInvocation (PrivateHack)

- (void)invokeUsingIMP:(IMP)imp;

@end

@implementation NVMAspectInvocation

- (void)invokeWithTarget:(id)target {
  NSAssert(NO, @"Can't change target for this invocation");
}

- (void)invoke {
  if (self.imp) {
    [self invokeUsingIMP:self.imp];
  }
}

@end

@implementation NVMAspectInfo

@end

NSString *const NVMAspectErrorDomain = @"AspectErrorDomain";

static void MessageInterpreter(ffi_cif *cif, void *ret,
                               void **args, void *userdata) {
  AspectData *data = (__bridge AspectData *)userdata;
  NSUInteger numberOfArguments = data.blockSignature.numberOfArguments;
  
  NVMAspectInvocation *methodInvocation = (id)[NVMAspectInvocation invocationWithMethodSignature:data.methodSignature];
  methodInvocation.imp = data.oriIMP;
  for (NSUInteger idx = 0; idx < numberOfArguments; idx++) {
    [methodInvocation setArgument:args[idx] atIndex:idx];
  }
  
  NVMAspectInfo *info = [NVMAspectInfo new];
  info.slf = (__bridge id) (args[0]);
  info.selector = info.selector;
  info.oriInvocation = methodInvocation;
  
  NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:data.blockSignature];
  if (numberOfArguments > 1) {
    [blockInvocation setArgument:&info atIndex:1];
  }
  for (NSUInteger idx = 2; idx < numberOfArguments; idx++) {
    [blockInvocation setArgument:args[idx] atIndex:idx];
  }
  
  [blockInvocation invokeWithTarget:data.impBlock];
  if (!data.hasNoReturnValue) {
    [blockInvocation getReturnValue:ret];
  }
  
  data = nil;
}

@implementation NSObject (NVMAspects)

+ (void)nvm_hookSelector:(SEL)selector
              usingBlock:(id)block
                   error:(NSError **)error {
  AspectData *data = [AspectData aspectDataWithClass:self selector:selector
                                            impBlock:block error:error];
  if (!data) {
    return;
  }
  
  NSMethodSignature *methodSignature = data.methodSignature;
  NSUInteger argCount = methodSignature.numberOfArguments;
  ffi_type *returnType = ffiTypeFromEncodingChar(methodSignature.methodReturnType);
  ffi_type **argTypes = malloc(sizeof(ffi_type *) *argCount);
  for (int i = 0; i < argCount; i++) {
    argTypes[i] = ffiTypeFromEncodingChar([methodSignature getArgumentTypeAtIndex:i]);
  }
  ffi_cif *cif = malloc(sizeof(ffi_cif));
  ffi_status status = ffi_prep_cif(cif, FFI_DEFAULT_ABI,
                                  (unsigned int)argCount, returnType, argTypes);
  if (status != FFI_OK) {
    return;
  }
  
  IMP newIMP = NULL;
  Method method = class_getInstanceMethod(self, selector);
  
  void *userData = (void *)(__bridge_retained CFTypeRef)data;
  ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
  ffi_prep_closure_loc(closure, cif, &MessageInterpreter, userData, NULL);
  
  if (method) {
    method_setImplementation(method, newIMP);
  } else {
    class_addMethod(self, selector, newIMP,
                    MethodTypesFromSignature(methodSignature).UTF8String);
  }
}

- (void)nvm_hookSelector:(SEL)selector
              usingBlock:(id)block
                   error:(NSError **)error {
  
}

@end
