//
//  AspectData.m
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import "AspectData.h"
#import "Aspects.h"
#import "Utils.h"

@interface NVMAspectData ()

@property (nonatomic, unsafe_unretained, readwrite) Class cls;
@property (nonatomic, assign, readwrite) SEL selector;
@property (nonatomic, strong, readwrite) NSMethodSignature *methodSignature;

@property (nonatomic, assign, readwrite) IMP oriIMP;

@property (nonatomic, copy, readwrite) id impBlock;
@property (nonatomic, strong, readwrite) NSMethodSignature *blockSignature;

@end

@implementation NVMAspectData

+ (instancetype)aspectDataWithClass:(Class)cls
                           selector:(SEL)selector
                           impBlock:(id)impBlock
                              error:(NSError *__autoreleasing *)error {
  NSMethodSignature *blockSignature = BlockSignature(impBlock, error);
  if (!blockSignature) {
    return nil;
  }
  NSMethodSignature *methodSignature = [cls instanceMethodSignatureForSelector:selector];
  if (methodSignature) {
    if (!IsCompatibleWithBlockSignature(methodSignature, blockSignature, error)) {
      return nil;
    }
  } else {
    methodSignature = MethodSignatureFromBlockSignature(blockSignature);
  }
  
  NVMAspectData *data = [NVMAspectData new];
  data.cls = cls;
  data.selector = selector;
  data.methodSignature = methodSignature;
  data.hasNoReturnValue = MethodTypeMatch(methodSignature.methodReturnType,
                                          @encode(void));
  
  data.oriIMP = [cls instanceMethodForSelector:selector];
  data.impBlock = impBlock;
  data.blockSignature = blockSignature;
  
  return data;
}

// Block internals.
typedef NS_OPTIONS(int, _BlockFlags) {
  BlockFlagsHasCopyDisposeHelpers = (1 << 25),
  BlockFlagsHasSignature          = (1 << 30)
};

typedef struct _Block {
  __unused Class isa;
  _BlockFlags flags;
  __unused int reserved;
  void (__unused *invoke)(struct _Block *block, ...);
  struct {
    unsigned long int reserved;
    unsigned long int size;
    // requires AspectBlockFlagsHasCopyDisposeHelpers
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
    // requires AspectBlockFlagsHasSignature
    const char *signature;
    const char *layout;
  } *descriptor;
  // imported variables
} *_BlockRef;

static NSMethodSignature *BlockSignature(id block, NSError **error) {
  _BlockRef layout = (__bridge void *)block;
  if (!(layout->flags & BlockFlagsHasSignature)) {
    AspectLuckySetError(error, NVMAspectErrorMissingBlockSignature,
                        [NSString stringWithFormat:@"Block %@ missing a type signature.", block]);
    return nil;
  }
  void *desc = layout->descriptor;
  desc += 2 * sizeof(unsigned long int);
  if (layout->flags & BlockFlagsHasCopyDisposeHelpers) {
    desc += 2 * sizeof(void *);
  }
  if (!desc) {
    AspectLuckySetError(error, NVMAspectErrorMissingBlockSignature,
                        [NSString stringWithFormat:@"Block %@ missing a type signature.", block]);
    return nil;
  }
  const char *signature = (*(const char **)desc);
  return [NSMethodSignature signatureWithObjCTypes:signature];
}

static BOOL IsCompatibleWithBlockSignature(NSMethodSignature *methodSignature,
                                           NSMethodSignature *blockSignature,
                                           NSError **error) {
  NSCParameterAssert(blockSignature);
  NSCParameterAssert(methodSignature);
  
  BOOL signaturesMatch = YES;
  if (blockSignature.numberOfArguments > methodSignature.numberOfArguments) {
    signaturesMatch = NO;
  }else {
    if (blockSignature.numberOfArguments > 1) {
      const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
      if (blockType[0] != '@') {
        signaturesMatch = NO;
      }
    }
    
    if (signaturesMatch) {
      if (!MethodTypeMatch([methodSignature methodReturnType],
                           [blockSignature methodReturnType])) {
        signaturesMatch = NO;
      }
    }
    
    // Argument 0 is self/block, argument 1 is SEL or id<AspectInfo>. We start comparing at argument 2.
    // The block can have less arguments than the method, that's ok.
    if (signaturesMatch) {
      for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
        // Only compare parameter, not the optional type data.
        if (!MethodTypeMatch([methodSignature getArgumentTypeAtIndex:idx],
                             [blockSignature getArgumentTypeAtIndex:idx])) {
          signaturesMatch = NO; break;
        }
      }
    }
  }
  
  if (!signaturesMatch) {
    NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
    AspectLuckySetError(error, NVMAspectErrorIncompatibleBlockSignature, description);
    return NO;
  }
  return YES;
}

static NSMethodSignature *MethodSignatureFromBlockSignature(NSMethodSignature *blockSignature) {
  NSMutableString *sig = [NSMutableString stringWithFormat:@"%s%s%s", blockSignature.methodReturnType, @encode(id), @encode(SEL)];
  for (NSInteger step = 2; step < blockSignature.numberOfArguments; step++) {
    NSString *argType = [NSString stringWithUTF8String:[blockSignature getArgumentTypeAtIndex:step]];
    [sig stringByAppendingString:argType];
  }
  return [NSMethodSignature signatureWithObjCTypes:sig.UTF8String];
}

@end