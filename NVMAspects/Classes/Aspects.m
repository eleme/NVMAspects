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
  NVMAspectData *data = (__bridge NVMAspectData *)userdata;
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

static inline BOOL HookClass(Class class, SEL selector,
                             id block, NSError **error) {
  NVMAspectData *data = [NVMAspectData aspectDataWithClass:class
                                                  selector:selector
                                                  impBlock:block
                                                     error:error];
  if (!data) {
    return NO;
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
    AspectLuckySetError(error, NVMAspectErrorFailToAllocTrampoline,
                        @"Fail to alloc ffi_cif for trampoline, this should really rare.");
    return NO;
  }
  
  IMP newIMP = NULL;
  void *userData = (void *)(__bridge_retained CFTypeRef)data;
  ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&newIMP);
  status = ffi_prep_closure_loc(closure, cif, &MessageInterpreter, userData, newIMP);
  
  if (status != FFI_OK) {
    AspectLuckySetError(error, NVMAspectErrorFailToAllocTrampoline,
                        @"Fail to alloc ffi_closure for trampoline, this should really rare.");
    return NO;
  }
  
  Method method = class_getInstanceMethod(class, selector);
  if (method) {
    method_setImplementation(method, newIMP);
  } else {
    class_addMethod(class, selector, newIMP,
                    MethodTypesFromSignature(methodSignature).UTF8String);
  }
  
  return YES;
}

@implementation NSObject (NVMAspects)

+ (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block
                      error:(NSError *__autoreleasing *)error {
  return HookClass(object_getClass(self), selector, block, error);
}

+ (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block
                         error:(NSError *__autoreleasing *)error  {
   return HookClass(self, selector, block, error);
}

- (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block
                         error:(NSError *__autoreleasing *)error {
  return [[self class] nvm_hookInstanceMethod:selector
                                   usingBlock:block error:error];
}

- (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block
                      error:(NSError *__autoreleasing *)error {
  return [[self class] nvm_hookClassMethod:selector
                                usingBlock:block error:error];
}

@end
