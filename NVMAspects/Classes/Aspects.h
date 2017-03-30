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
@property (nonatomic, strong) NSInvocation *oriInvocation;

@end

extern NSString *const NVMAspectErrorDomain;

@interface NSObject (NVMAspects)

+ (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block
                         error:(NSError **)error;
+ (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block
                      error:(NSError **)error;

- (BOOL)nvm_hookInstanceMethod:(SEL)selector
                    usingBlock:(id)block
                         error:(NSError **)error;
- (BOOL)nvm_hookClassMethod:(SEL)selector
                 usingBlock:(id)block
                      error:(NSError **)error;

@end
