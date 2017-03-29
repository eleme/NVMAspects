//
//  Utils.m
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "Utils.h"
#import "Aspects.h"

ffi_type * ffiTypeFromEncodingChar(const char *c) {
  switch (c[0]) {
    case 'v':
      return &ffi_type_void;
    case 'c':
      return &ffi_type_schar;
    case 'C':
      return &ffi_type_uchar;
    case 's':
      return &ffi_type_sshort;
    case 'S':
      return &ffi_type_ushort;
    case 'i':
      return &ffi_type_sint;
    case 'I':
      return &ffi_type_uint;
    case 'l':
      return &ffi_type_slong;
    case 'L':
      return &ffi_type_ulong;
    case 'q':
      return &ffi_type_sint64;
    case 'Q':
      return &ffi_type_uint64;
    case 'f':
      return &ffi_type_float;
    case 'd':
      return &ffi_type_double;
    case 'B':
      return &ffi_type_uint8;
    case '^':
      return &ffi_type_pointer;
    case '@':
      return &ffi_type_pointer;
    case '#':
      return &ffi_type_pointer;
    case ':':
      return &ffi_type_pointer;
  }
  return NULL;
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
