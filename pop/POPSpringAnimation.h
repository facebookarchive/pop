/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <pop/POPPropertyAnimation.h>

/**
 @abstract A concrete spring animation class.
 @discussion Animation is achieved through modeling spring dynamics.
 */
@interface POPSpringAnimation : POPPropertyAnimation

/**
 @abstract The designated initializer.
 @returns An instance of a spring animation.
 */
+ (instancetype)animation;

/**
 @abstract Convenience initializer that returns an animation with animatable property of name.
 @param name The name of the animatable property.
 @returns An instance of a spring animation configured with specified animatable property.
 */
+ (instancetype)animationWithPropertyNamed:(NSString *)name;

/**
 @abstract The current velocity value.
 @discussion Set before animation start to account for initial velocity. Expressed in change of value units per second.
 */
@property (copy, nonatomic) id velocity;

/**
 @abstract The effective bounciness.
 @discussion Use in conjunction with 'springSpeed' to change animation effect. Values are converted into corresponding dynamics constants. Higher values increase spring movement range resulting in more oscillations and springiness. Defined as a value in the range [0, 20]. Defaults to 4.
 */
@property (assign, nonatomic) CGFloat springBounciness;

/**
 @abstract The effective speed.
 @discussion Use in conjunction with 'springBounciness' to change animation effect. Values are converted into corresponding dynamics constants. Higher values increase the dampening power of the spring resulting in a faster initial velocity and more rapid bounce slowdown. Defined as a value in the range [0, 20]. Defaults to 12.
 */
@property (assign, nonatomic) CGFloat springSpeed;

/**
 @abstract The tension used in the dynamics simulation.
 @discussion Can be used over bounciness and speed for finer grain tweaking of animation effect.
 */
@property (assign, nonatomic) CGFloat dynamicsTension;

/**
 @abstract The friction used in the dynamics simulation.
 @discussion Can be used over bounciness and speed for finer grain tweaking of animation effect.
 */
@property (assign, nonatomic) CGFloat dynamicsFriction;

/**
 @abstract The mass used in the dynamics simulation.
 @discussion Can be used over bounciness and speed for finer grain tweaking of animation effect.
 */
@property (assign, nonatomic) CGFloat dynamicsMass;

@end
