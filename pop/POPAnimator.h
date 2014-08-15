/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/NSObject.h>

@protocol POPAnimatorDelegate;

/**
 @abstract The animator class renders animations.
 */
@interface POPAnimator : NSObject

/**
 @abstract The shared animator instance.
 @discussion Consumers should generally use the shared instance in lieu of creating new instances.
 */
+ (instancetype)sharedAnimator;

/**
 @abstract The optional animator delegate.
 */
@property (weak, nonatomic) id<POPAnimatorDelegate> delegate;

@end

/**
 @abstract The animator delegate.
 */
@protocol POPAnimatorDelegate <NSObject>

/**
 @abstract Called on each frame before animation application.
 */
- (void)animatorWillAnimate:(POPAnimator *)animator;

/**
 @abstract Called on each frame after animation application.
 */
- (void)animatorDidAnimate:(POPAnimator *)animator;

@end

////////////////////////////////////////////////////////////
@class POPAnimation;

////////////////////////////////////////////////////////////
// POPAnimationGroup
@interface POPAnimationGroup : NSObject
@property (nonatomic, copy) void (^completionBlock)();

- (void)addAnimation:(POPAnimation *)anim forObject:(id)obj key:(NSString *)key;
- (void)removeAnimationForObject:(id)obj key:(NSString *)key;
@end

////////////////////////////////////////////////////////////
// POPAnimator (NPExtensions)
@interface POPAnimator (NPExtensions)
- (void)batchAddRemoveAnimations:(void (^)(POPAnimationGroup * group))block;
- (void)addAnimationsForObject:(id)obj withDictionary:(NSDictionary *)animationsDictionary;
@end