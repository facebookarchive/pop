/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

/**
 @abstract Enumeraton of animation event types.
 */
typedef NS_ENUM(NSUInteger, POPAnimationEventType) {
  kPOPAnimationEventPropertyRead = 0,
  kPOPAnimationEventPropertyWrite,
  kPOPAnimationEventToValueUpdate,
  kPOPAnimationEventFromValueUpdate,
  kPOPAnimationEventVelocityUpdate,
  kPOPAnimationEventBouncinessUpdate,
  kPOPAnimationEventSpeedUpdate,
  kPOPAnimationEventFrictionUpdate,
  kPOPAnimationEventMassUpdate,
  kPOPAnimationEventTensionUpdate,
  kPOPAnimationEventDidStart,
  kPOPAnimationEventDidStop,
  kPOPAnimationEventDidReachToValue,
};

/**
 @abstract The base animation event class.
 */
@interface POPAnimationEvent : NSObject

/**
 @abstract The event type. See {@ref POPAnimationEventType} for possible values.
 */
@property (readonly, nonatomic, assign) POPAnimationEventType type;

/**
 @abstract The time of event.
 */
@property (readonly, nonatomic, assign) CFTimeInterval time;

/**
 @abstract Optional string describing the animation at time of event.
 */
@property (readonly, nonatomic, copy) NSString *animationDescription;

@end

/**
 @abstract An animation event subclass for recording value and velocity.
 */
@interface POPAnimationValueEvent : POPAnimationEvent

/**
 @abstract The value recorded.
 */
@property (readonly, nonatomic, strong) id value;

/**
 @abstract The velocity recorded, if any.
 */
@property (readonly, nonatomic, strong) id velocity;

@end
