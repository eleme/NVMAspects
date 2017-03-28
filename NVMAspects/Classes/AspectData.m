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

@interface AspectData ()

@property (nonatomic, unsafe_unretained, readwrite) Class cls;
@property (nonatomic, assign, readwrite) SEL selector;
@property (nonatomic, strong, readwrite) NSMethodSignature *selectorSignature;

@property (nonatomic, assign, readwrite) IMP oriIMP;

@property (nonatomic, copy, readwrite) id impBlock;
@property (nonatomic, strong, readwrite) NSMethodSignature *blockSignature;

@end

@implementation AspectData

+ (instancetype)aspectDataWithClass:(Class)cls
                           selector:(SEL)selector
                           impBlock:(id)impBlock
                              error:(NSError *__autoreleasing *)error {
  NSMethodSignature *blockSignature = BlockSignature(impBlock, error);
  if (!blockSignature) {
    return nil;
  }
  NSMethodSignature *selectorSignature = [cls instanceMethodSignatureForSelector:selector];
  if (selectorSignature) {
    if (!IsCompatibleWithBlockSignature(blockSignature, selectorSignature, error)) {
      return nil;
    }
  } else {
    
  }
  
  AspectData *data = [AspectData new];
  data.cls = cls;
  data.selector = selector;
  data.selectorSignature = selectorSignature;
  
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
    AspectLuckySetError(error, AspectErrorMissingBlockSignature,
                        [NSString stringWithFormat:@"Block %@ missing a type signature.", block]);
    return nil;
  }
  void *desc = layout->descriptor;
  desc += 2 * sizeof(unsigned long int);
  if (layout->flags & BlockFlagsHasCopyDisposeHelpers) {
    desc += 2 * sizeof(void *);
  }
  if (!desc) {
    AspectLuckySetError(error, AspectErrorMissingBlockSignature,
                        [NSString stringWithFormat:@"Block %@ missing a type signature.", block]);
    return nil;
  }
  const char *signature = (*(const char **)desc);
  return [NSMethodSignature signatureWithObjCTypes:signature];
}

static BOOL IsCompatibleWithBlockSignature(NSMethodSignature *blockSignature,
                                           NSMethodSignature *methodSignature,
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
    // Argument 0 is self/block, argument 1 is SEL or id<AspectInfo>. We start comparing at argument 2.
    // The block can have less arguments than the method, that's ok.
    if (signaturesMatch) {
      for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
        const char *methodType = [methodSignature getArgumentTypeAtIndex:idx];
        const char *blockType = [blockSignature getArgumentTypeAtIndex:idx];
        // Only compare parameter, not the optional type data.
        if (!methodType || !blockType || methodType[0] != blockType[0]) {
          signaturesMatch = NO; break;
        }
      }
    }
  }
  
  if (!signaturesMatch) {
    NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
    AspectLuckySetError(error, AspectErrorIncompatibleBlockSignature, description);
    return NO;
  }
  return YES;
}

@end
