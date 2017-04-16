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
  structType->alignment = align;
  structType->size = size;
  structType->type = FFI_TYPE_STRUCT;
  structType->elements = elementsInStructsForEncodingChar(c);
  
  return structType;
}

static inline ffi_type * ffiTypeForPrimitiveEncodingChar(const char *c) {
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

ffi_type *ffiTypeForCArrayEncoding(char const *encoding) {
  long len = strlen(encoding);
  const char *primitiveTypeEncoding = NULL;
  for (long position = len - 1; position >= 0; position--) {
    if (encoding[position] >= '0' && encoding[position] <= '9') {
      primitiveTypeEncoding = &encoding[position + 1];
      break;
    }
  }
  
  ffi_type *primitiveType = ffiTypeForPrimitiveEncodingChar(primitiveTypeEncoding);
  NSCAssert(primitiveType, nil);
  
  NSUInteger size = 0;
  NSUInteger align = 0;
  NSGetSizeAndAlignment(encoding, &size, &align);
  ffi_type *cAarrayType = malloc(sizeof(ffi_type));
  cAarrayType->size = size;
  cAarrayType->alignment = align;
  // use a struct to simulate a c array
  cAarrayType->type = FFI_TYPE_STRUCT;
  
  NSInteger elementCount = size / primitiveType->size;
  ffi_type **elements = malloc(sizeof(void *) *(elementCount + 1));
  for (NSInteger index = 0; index < elementCount; index++) {
    elements[index] = primitiveType;
  }
  elements[elementCount] = NULL;
  
  cAarrayType->elements = elements;
  return cAarrayType;
}

static inline char const *startPositionForStructElement(char const *encoding) {
  // struct encoding is like this:"{CGRect={CGPoint=dd}{CGSize=dd}}"
  // so first element is after '='
  while (encoding[0] != '=') {
    encoding++; // trim to =
  }
  encoding++;   //trim =
  
  return encoding;
}

static inline ffi_type ** elementsInStructsForEncodingChar(const char *encoding) {
  encoding = startPositionForStructElement(encoding);
  
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

static inline const char *trimedEncodingChar(const char *c) {
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

static inline bool isExtraEncoding(char encoding) {
  return encoding == '"' || encoding == '<';
}

BOOL MethodTypeMatch(const char *type, const char *otherType) {
  unsigned long typeLen = strlen(type);
  unsigned long otherTypeLen = strlen(otherType);
  unsigned long minLen = MIN(typeLen, otherTypeLen);
  
  if (minLen == 0) {
    return NO;
  }
  
  bool equal = strncmp(type, otherType, minLen) == 0;
  if (typeLen > minLen) {
    equal = isExtraEncoding(type[minLen]);
  }
  if (otherTypeLen > minLen) {
    equal = isExtraEncoding(otherType[minLen]);
  }
  
  return equal;
}

NSString *MethodTypesFromSignature(NSMethodSignature *signature) {
  NSMutableString *string = [NSMutableString stringWithFormat:@"%s", signature.methodReturnType];
  for (NSInteger i = 0; i < signature.numberOfArguments; i++) {
    [string appendString:[NSString stringWithUTF8String:[signature getArgumentTypeAtIndex:i]]];
  }
  return string;
}

@implementation NSObject (ST)

+ (void)load {
  typedef char array[3][3];
  NSUInteger size = 0;
  NSUInteger align = 0;
  NSGetSizeAndAlignment(@encode(array), &size, &align);
  ffi_type *type = ffiTypeForCArrayEncoding(@encode(array));
}

@end
