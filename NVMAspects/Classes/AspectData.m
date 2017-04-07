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

static NSString *const SignatureNote = @""
"Block's signature should compatible with method."
"This means they have same return type,"
"and block take a NVMAspectInfo as first argument, then other agrs pass to the method";

@interface NVMAspectData ()

@property (nonatomic, unsafe_unretained, readwrite) Class cls;
@property (nonatomic, assign, readwrite) SEL selector;
@property (nonatomic, strong, readwrite) NSMethodSignature *methodSignature;

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
  if (!methodSignature) {
    methodSignature = MethodSignatureFromBlockSignature(blockSignature);
  }
  
  if (!IsCompatibleWithBlockSignature(methodSignature, blockSignature, error)) {
    NSAssert(NO, SignatureNote);
    return nil;
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

- (NSString *)description {
  return [NSString stringWithFormat:@"Aspect data for selector:%@ in class %@",
          NSStringFromSelector(self.selector),
          self.cls];
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
  
  BOOL signaturesMatch = (blockSignature.numberOfArguments == methodSignature.numberOfArguments &&
                          blockSignature.numberOfArguments >= 2);
  if (signaturesMatch) {
    const char *blockType = [blockSignature getArgumentTypeAtIndex:1];
    signaturesMatch = MethodTypeMatch(blockType, "@");
  }
  
  if (signaturesMatch) {
    signaturesMatch = MethodTypeMatch([methodSignature methodReturnType],
                                      [blockSignature methodReturnType]);
  }
  
  if (signaturesMatch) {
    for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
      // Only compare parameter, not the optional type data.
      signaturesMatch = MethodTypeMatch([methodSignature getArgumentTypeAtIndex:idx],
                                        [blockSignature getArgumentTypeAtIndex:idx]);
      if (!signaturesMatch) {
        break;
      }
    }
  }
  
  if (!signaturesMatch) {
    NSString *description = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
    AspectLuckySetError(error, NVMAspectErrorIncompatibleBlockSignature, description);
  }
  
  return signaturesMatch;
}

static NSMethodSignature *MethodSignatureFromBlockSignature(NSMethodSignature *blockSignature) {
  NSMutableString *sig = [NSMutableString stringWithFormat:@"%s%s%s", blockSignature.methodReturnType, @encode(id), @encode(SEL)];
  for (NSInteger step = 2; step < blockSignature.numberOfArguments; step++) {
    NSString *argType = [NSString stringWithUTF8String:[blockSignature getArgumentTypeAtIndex:step]];
    [sig appendString:argType];
  }
  return [NSMethodSignature signatureWithObjCTypes:sig.UTF8String];
}

@end
