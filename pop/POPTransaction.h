//
//  POPTransaction.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/**
 @abstract Describes a pop transaction
 @discussion Transactions are a mechanism used to batch shorthand animations into on "atomic" operation. There are 2 kinds of transactions. Explicit transactions are where the programmer calls [POPTransaction begin] before animating objects using shorthand and [POPTransaction commit] after adding the animations. Once commit is called, all animations within the transaction are adding to their respective objects and animated. Implicit transactions are created when shorthand animations are created on the fly without any surrounding transaction.
 */
@interface POPTransaction : NSObject

/**
 @abstract Begin a transaction.
 @discussion Starts a transaction for the current thread. transactions are nestable.
 */
+ (void)begin;

/**
 @abstract Commit a transaction.
 @discussion Commits all shorthand animations added during the current transaction.
 */
+ (void)commit;

/**
 @abstract Accessors for the "animationDuration" per-thread transaction.
 */
+ (CFTimeInterval)animationDuration;
+ (void)setAnimationDuration:(CFTimeInterval)dur;

/**
 @abstract Accessors for the "animationTimingFunction" per-thread transaction.
 */
+ (CAMediaTimingFunction *)animationTimingFunction;
+ (void)setAnimationTimingFunction:(CAMediaTimingFunction *)function;

/**
 @abstract Accessors for the "animationTimingFunction" per-thread transaction.
 */
+ (BOOL)disableActions;
+ (void)setDisableActions:(BOOL)flag;

/**
 @abstract Accessors for the "completionBlock" per-thread transaction.
 */
+ (void (^)(void))completionBlock;
+ (void)setCompletionBlock:(void (^)(void))block;

@end

