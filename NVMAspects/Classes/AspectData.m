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

static NSString *const NilSignatureNote = @""
"Block and Method should all have signature,"
"if you try to add a method to a class,"
"please call class_addPlaceholderIfNoImplement first.";

static NSString *const SignatureNote = @""
"Block's signature should compatible with method."
"This means they have same return type,"
"but block take NVMAspectInfo as first argument, then method args";

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
  NSMethodSignature *methodSignature = [cls instanceMethodSignatureForSelector:selector];
  
  BOOL allHave = blockSignature && methodSignature;
  NSAssert(allHave, NilSignatureNote);
  if (!allHave) {
    return nil;
  }
  
  if (!IsCompatibleWithBlockSignature(methodSignature, blockSignature, error)) {
    NSAssert(NO, SignatureNote);
    return nil;
  }
  
  NVMAspectData *data = [NVMAspectData new];
  data.cls = cls;
  data.selector = selector;
  data.methodSignature = methodSignature;
  data.hasReturnValue = !ObjCTypeIsEqual(methodSignature.methodReturnType,
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
  NSCAssert(signaturesMatch, nil);
  
  if (signaturesMatch) {
    signaturesMatch = ObjCTypeIsEqual([blockSignature getArgumentTypeAtIndex:1],
                                      @encode(NVMAspectInfo *));
    
    NSCAssert(signaturesMatch, nil);
  }
  
  if (signaturesMatch) {
    for (NSUInteger idx = 2; idx < blockSignature.numberOfArguments; idx++) {
      // Only compare parameter, not the optional type data.
      signaturesMatch = ObjCTypeIsEqual([methodSignature getArgumentTypeAtIndex:idx],
                                        [blockSignature getArgumentTypeAtIndex:idx]);
      if (!signaturesMatch) {
        NSCAssert(signaturesMatch, nil);
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

@end
