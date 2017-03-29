//
//  AspectData.h
//  NVMAspects
//
//  Created by Karl Peng on 3/28/17.
//  Copyright © 2017 Rajax Network Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AspectData : NSObject

+ (instancetype)aspectDataWithClass:(Class)cls
                           selector:(SEL)selector
                           impBlock:(id)impBlock
                              error:(NSError **)error;

@property (nonatomic, unsafe_unretained, readonly) Class cls;
@property (nonatomic, assign, readonly) SEL selector;
@property (nonatomic, strong, readonly) NSMethodSignature *methodSignature;

@property (nonatomic, assign) BOOL hasNoReturnValue;

@property (nonatomic, assign, readonly) IMP oriIMP;

@property (nonatomic, copy, readonly) id impBlock;
@property (nonatomic, strong, readonly) NSMethodSignature *blockSignature;

@end
