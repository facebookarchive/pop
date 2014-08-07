/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <pop/POPAnimation.h>

@class POPCustomAnimation;

/**
 @abstract POPCustomAnimationBlock is the callback block of a custom animation.
 @discussion This block will be executed for each animation frame and should update the property or properties being animated based on current timing.
 @param target The object being animated. Reference the passed in target to help avoid retain loops.
 @param animation The custom animation instance. Use to determine the current and elapsed time since last callback. Reference the passed in animation to help avoid retain loops.
 @return Flag indicating whether the animation should continue animating. Return NO to indicate animation is done.
 */
typedef BOOL (^POPCustomAnimationBlock)(id target, POPCustomAnimation *animation);

/**
 @abstract POPCustomAnimation is a concrete animation subclass for custom animations.
 */
@interface POPCustomAnimation : POPAnimation

/**
@abstract Creates and returns an initialized custom animation instance.
@discussion This is the designated initializer.
@param block The custom animation callback block. See {@ref POPCustomAnimationBlock}.
@return The initialized custom animation instance.
*/
+ (instancetype)animationWithBlock:(POPCustomAnimationBlock)block;

/**
 @abstract The current animation time at time of callback.
 */
@property (readonly, nonatomic) CFTimeInterval currentTime;

/**
 @abstract The elapsed animation time since last callback.
 */
@property (readonly, nonatomic) CFTimeInterval elapsedTime;

@end
