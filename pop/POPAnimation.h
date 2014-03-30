/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/NSObject.h>

#import <POP/POPAnimationTracer.h>
#import <POP/POPGeometry.h>

@class CAMediaTimingFunction;

/**
 @abstract The abstract animation base class.
 @discussion Instantiate and use one of the concrete animation subclasses.
 */
@interface POPAnimation : NSObject

/**
 @abstract The name of the animation.
 @discussion Optional property to help identify the animation.
 */
@property (copy, nonatomic) NSString *name;

/**
 @abstract The beginTime of the animation in media time.
 @discussion Defaults to 0 and starts immediately.
 */
@property (assign, nonatomic) CFTimeInterval beginTime;

/**
 @abstract The animation delegate.
 @discussion See {@ref POPAnimationDelegate} for details.
 */
@property (weak, nonatomic) id delegate;

/**
 @abstract The animation tracer.
 @discussion Returns the existing tracer, creating one if needed. Call start/stop on the tracer to toggle event collection.
 */
@property (readonly, nonatomic) POPAnimationTracer *tracer;

/**
 @abstract Optional block called on animation completion.
 */
@property (copy, nonatomic) void (^completionBlock)(POPAnimation *anim, BOOL finished);

/**
 @abstract Flag indicating whether animation should be removed on completion.
 @discussion Setting to NO can facilitate animation reuse. Defaults to YES.
 */
@property (assign, nonatomic) BOOL removedOnCompletion;

/**
 @abstract Flag indicating whether animation is paused.
 @discussion A paused animation is excluded from the list of active animations. On initial creation, defaults to YES. On animation addition, the animation is implicity unpaused. On animation completion, the animation is implicity paused including for animations with removedOnCompletion set to NO.
 */
@property (assign, nonatomic, getter = isPaused) BOOL paused;

@end

/**
 @abstract The animation delegate.
 */
@protocol POPAnimationDelegate <NSObject>
@optional

/**
 @abstract Called on animation start.
 @param anim The relevant animation.
 */
- (void)pop_animationDidStart:(POPAnimation *)anim;

/**
 @abstract Called when value meets or exceeds to value.
 @param anim The relevant animation.
 */
- (void)pop_animationDidReachToValue:(POPAnimation *)anim;

/**
 @abstract Called on animation stop.
 @param anim The relevant animation.
 @param finished Flag indicating finished state. Flag is true if the animation reached completion before being removed.
 */
- (void)pop_animationDidStop:(POPAnimation *)anim finished:(BOOL)finished;

/**
 @abstract Called each frame animation is applied.
 @param anim The relevant animation.
 */
- (void)pop_animationDidApply:(POPAnimation *)anim;

@end


@interface NSObject (POP)

/**
 @abstract Add an animation to the reciver.
 @param anim The animation to add.
 @param key The key used to identify the animation.
 @discussion The 'key' may be any string such that only one animation per unique key is added per object.
 */
- (void)pop_addAnimation:(POPAnimation *)anim forKey:(NSString *)key;

/**
 @abstract Remove all animations attached to the receiver.
 */
- (void)pop_removeAllAnimations;

/**
 @abstract Remove any animation attached to the receiver for 'key'.
 @param key The key used to identify the animation.
 */
- (void)pop_removeAnimationForKey:(NSString *)key;

/**
 @abstract Returns an array containing the keys of all animations currently attached to the receiver.
 @param The order of keys reflects the order in which animations will be applied.
 */
- (NSArray *)pop_animationKeys;

/**
 @abstract Returns any animation attached to the receiver.
 @param key The key used to identify the animation.
 @returns The animation currently attached, or nil if no such animation exists.
 */
- (id)pop_animationForKey:(NSString *)key;

@end
