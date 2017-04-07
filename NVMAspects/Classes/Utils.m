//
//  Utils.m
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "Utils.h"
#import <objc/runtime.h>
#import "Aspects.h"

static inline ffi_type ** elementsInStructsForEncodingChar(const char *encoding);
static inline ffi_type *ffiTypeForStructEncodingChar(const char *c);

// Struct encoding is a magic.
static inline ffi_type *ffiTypeForStructEncodingChar(const char *c) {
  NSUInteger size = 0;
  NSUInteger align = 0;
  NSGetSizeAndAlignment(c, &size, &align);
  ffi_type **elements = elementsInStructsForEncodingChar(c);
  if (size && elements == NULL) {
    NSCAssert(NO, @"should have elements");
    return NULL;
  }
  
  ffi_type *structType = malloc(sizeof(ffi_type));
  structType->alignment = 0;
  structType->size = 0;
  structType->type = FFI_TYPE_STRUCT;
  structType->elements = elementsInStructsForEncodingChar(c);
  
  return structType;
}

ffi_type * ffiTypeForPrimitiveEncodingChar(const char *c) {
  if (!c || !strlen(c)) {
    return NULL;
  }
  
  switch (c[0]) {
    case _C_ID:
      return &ffi_type_pointer;
    case _C_CLASS:
      return &ffi_type_pointer;
    case _C_SEL:
      return &ffi_type_pointer;
    case _C_CHR:
      return &ffi_type_schar;
    case _C_UCHR:
      return &ffi_type_uchar;
    case _C_SHT:
      return &ffi_type_sshort;
    case _C_USHT:
      return &ffi_type_ushort;
    case _C_INT:
      return &ffi_type_sint;
    case _C_UINT:
      return &ffi_type_uint;
    case _C_LNG:
      return &ffi_type_slong;
    case _C_ULNG:
      return &ffi_type_ulong;
    case _C_LNG_LNG:
      return &ffi_type_sint64;
    case _C_ULNG_LNG:
      return &ffi_type_uint64;
    case _C_FLT:
      return &ffi_type_float;
    case _C_DBL:
      return &ffi_type_double;
    case _C_BOOL:
      return &ffi_type_uint8;
    case _C_VOID:
      return &ffi_type_void;
    case _C_PTR:
      return &ffi_type_pointer;
  }
  
  return NULL;
}

static char const *whereStructElementStart(char const *encoding) {
  // struct encoding is like this:"{CGRect={CGPoint=dd}{CGSize=dd}}"
  // so first element is after '='
  while (encoding[0] != '=') {
    encoding++; // trim to =
  }
  encoding++;   //trim =
  
  return encoding;
}

static inline ffi_type ** elementsInStructsForEncodingChar(const char *encoding) {
  encoding = whereStructElementStart(encoding);
  
  NSPointerArray *array = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsOpaqueMemory];
  while (encoding[0] != _C_STRUCT_E) {
    const char *start = encoding;
    const char *end = NSGetSizeAndAlignment(start, NULL, NULL);
    ffi_type *type = NULL;
    if (start[0] == _C_STRUCT_B) {
      type = ffiTypeForStructEncodingChar(start);
    } else {
      type = ffiTypeForPrimitiveEncodingChar(start);
    }
    
    NSCAssert(type, @"should have a type");
    if (!type) {
      return NULL;
    }
    
    [array addPointer:type];
    encoding = end;
  }
  
  NSInteger typeCount = array.count;
  ffi_type **types = calloc(typeCount + 1, sizeof(void *));
  for (NSUInteger step = 0; step < typeCount; step++) {
    types[step] = [array pointerAtIndex:step];
  }
  
  return types;
}

const char *trimedEncodingChar(const char *c) {
  NSCharacterSet *trimedEncodings = [NSCharacterSet characterSetWithCharactersInString:@"rnNoORV"];
  while ([trimedEncodings hasMemberInPlane:c[0]]) {
    // trim const and other in out identifier
    c = &c[1];
  }
  return c;
}

ffi_type * ffiTypeFromEncodingChar(const char *c) {
  if (!c || !strlen(c)) {
    return NULL;
  }
  c = trimedEncodingChar(c);
  if (c[0] == _C_STRUCT_B) {
    return ffiTypeForStructEncodingChar(c);
  }
  return ffiTypeForPrimitiveEncodingChar(c);
}

void AspectLuckySetError(NSError **error, NSInteger code, NSString *description) {
  if (error) {
    *error = [NSError errorWithDomain:NVMAspectErrorDomain
                                 code:code
                             userInfo:@{ NSLocalizedDescriptionKey: description}];
  }
}

BOOL MethodTypeMatch(const char *type, const char *otherType) {
  return type && otherType && type[0] == otherType[0];
}

NSString *MethodTypesFromSignature(NSMethodSignature *signature) {
  NSMutableString *string = [NSMutableString stringWithFormat:@"%s", signature.methodReturnType];
  for (NSInteger i = 0; i < signature.numberOfArguments; i++) {
    [string appendString:[NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:i]]];
  }
  return string;
}
