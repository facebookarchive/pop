//
//  POPTransaction.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface POPTransaction : NSObject

+ (void)begin;
+ (void)commit;

+ (void)lock;
+ (void)unlock;

+ (CFTimeInterval)animationDuration;
+ (void)setAnimationDuration:(CFTimeInterval)dur;

+ (CAMediaTimingFunction *)animationTimingFunction;
+ (void)setAnimationTimingFunction:(CAMediaTimingFunction *)function;

+ (BOOL)disableActions;
+ (void)setDisableActions:(BOOL)flag;

+ (void (^)(void))completionBlock;
+ (void)setCompletionBlock:(void (^)(void))block;

@end

extern NSString * const kPOPTransactionAnimationDuration;
extern NSString * const kPOPTransactionDisableActions;
extern NSString * const kPOPTransactionAnimationTimingFunction;
extern NSString * const kPOPTransactionCompletionBlock;
