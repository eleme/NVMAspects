//
//  Aspects.h
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NVMAspectErrorCode) {
  NVMAspectErrorMissingBlockSignature,
  NVMAspectErrorIncompatibleBlockSignature,
  NVMAspectErrorFailToAllocTrampoline,
  NVMAspectErrorUnsupportArgumentType,
};

@interface NVMAspectInfo : NSObject

@property (nonatomic, unsafe_unretained) id slf;
@property (nonatomic, assign) SEL selector;

@property (nonatomic, strong) NSInvocation *invocation;

@end

extern NSString *const NVMAspectErrorDomain;

/* Add a placeholder first if you don't sure cls has a implement,
 * this method provide a method signature to the runtime.
 */
extern BOOL class_addPlaceholderIfNoImplement(Class cls, SEL sel,
                                              NSMethodSignature* sig);

@interface NSObject (NVMAspects)

/* In practice, all error should be solved when release.
 */
+ (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block;

+ (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block;

/* When dynamic hook some class at runtime, you may want to get error info
 */
+ (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block
                         error:(NSError **)error;

+ (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block
                      error:(NSError **)error;

@end
