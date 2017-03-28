//
//  Aspects.h
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NVMAspectErrorCode) {
  AspectErrorSelectorBlacklisted,                   /// Selectors like release, retain, autorelease are blacklisted.
  AspectErrorMissingBlockSignature,                 /// The block misses compile time signature info and can't be called.
  AspectErrorIncompatibleBlockSignature,            /// The block signature does not match the method or is too large.
};

@interface NVMAspectInfo : NSObject

@property (nonatomic, unsafe_unretained) id slf;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) NSInvocation *oriInvocation;

@end

extern NSString *const NVMAspectErrorDomain;

@interface NSObject (NVMAspects)

+ (void)nvm_hookSelector:(SEL)selector
              usingBlock:(id)block
                   error:(NSError **)error;

- (void)nvm_hookSelector:(SEL)selector
              usingBlock:(id)block
                   error:(NSError **)error;

@end
