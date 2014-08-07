/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <pop/POPPropertyAnimation.h>

/**
 @abstract A concrete decay animation class.
 @discussion Animation is achieved through gradual decay of animation value.
 */
@interface POPDecayAnimation : POPPropertyAnimation

/**
 @abstract The designated initializer.
 @returns An instance of a decay animation.
 */
+ (instancetype)animation;

/**
 @abstract Convenience initializer that returns an animation with animatable property of name.
 @param name The name of the animatable property.
 @returns An instance of a decay animation configured with specified animatable property.
 */
+ (instancetype)animationWithPropertyNamed:(NSString *)name;

/**
 @abstract The current velocity value.
 @discussion Set before animation start to account for initial velocity. Expressed in change of value units per second. The only POPValueTypes supported for velocity are: kPOPValuePoint, kPOPValueInteger, kPOPValueFloat, kPOPValueRect, and kPOPValueSize.
 */
@property (copy, nonatomic) id velocity;

/**
 @abstract The original velocity value.
 @discussion Since the velocity property is modified as the animation progresses, this property stores the original, passed in velocity to support autoreverse and repeatCount.
 */
@property (copy, nonatomic, readonly) id originalVelocity;

/**
 @abstract The deceleration factor.
 @discussion Values specifies should be in the range [0, 1]. Lower values results in faster deceleration. Defaults to 0.998.
 */
@property (assign, nonatomic) CGFloat deceleration;

/**
 @abstract The expected duration.
 @discussion Derived based on input velocity and deceleration values.
 */
@property (readonly, assign, nonatomic) CFTimeInterval duration;

/**
 The to value is derived based on input velocity and deceleration.
 */
- (void)setToValue:(id)toValue NS_UNAVAILABLE;

/**
 @abstract The reversed velocity.
 @discussion The reversed velocity based on the originalVelocity when the animation was set up.
 */
- (id)reversedVelocity;

@end
