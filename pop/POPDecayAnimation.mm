/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPDecayAnimationInternal.h"

@implementation POPDecayAnimation

#pragma mark - Lifecycle

#undef __state
#define __state ((POPDecayAnimationState *)_state)

+ (instancetype)animation
{
  return [[self alloc] init];
}

+ (instancetype)animationWithPropertyNamed:(NSString *)aName
{
  POPDecayAnimation *anim = [self animation];
  anim.property = [POPAnimatableProperty propertyWithName:aName];
  return anim;
}

- (id)init
{
  return [self _init];
}

- (void)_initState
{
  _state = new POPDecayAnimationState(self);
}

#pragma mark - Properties

DEFINE_RW_PROPERTY(POPDecayAnimationState, deceleration, setDeceleration:, CGFloat, __state->toVec = NULL;);

@dynamic velocity;

- (id)toValue
{
  [self _ensureComputedProperties];
  return POPBox(__state->toVec, __state->valueType);
}

- (CFTimeInterval)duration
{
  [self _ensureComputedProperties];
  return __state->duration;
}

- (void)setFromValue:(id)fromValue
{
  super.fromValue = fromValue;
  [self _invalidateComputedProperties];
}

- (void)setToValue:(id)aValue
{
  // no-op
  NSLog(@"ignoring to value on decay animation %@", self);
}

- (id)velocity
{
  return POPBox(__state->velocityVec, __state->valueType);
}

- (void)setVelocity:(id)aValue
{
  VectorRef vec = POPUnbox(aValue, __state->valueType, __state->valueCount, YES);

  if (!vec_equal(vec, __state->velocityVec)) {
    __state->velocityVec = vec;

    if (__state->tracing) {
      [__state->tracer updateVelocity:aValue];
    }

    [self _invalidateComputedProperties];

    // automatically unpause active animations
    if (__state->active && __state->paused) {
      __state->fromVec = NULL;
      __state->setPaused(false);
    }
  }
}

#pragma mark - Utility

- (void)_ensureComputedProperties
{
  if (NULL == __state->toVec) {
    __state->computeDestinationValues();
  }
}

- (void)_invalidateComputedProperties
{
  __state->toVec = NULL;
  __state->duration = 0;
}

- (void)_appendDescription:(NSMutableString *)s debug:(BOOL)debug
{
  [super _appendDescription:s debug:debug];

  if (NULL != __state->toVec)
    [s appendFormat:@"; duration = %f", self.duration];

  if (__state->deceleration)
    [s appendFormat:@"; deceleration = %f", __state->deceleration];
}

@end
