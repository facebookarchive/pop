/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPDecayAnimationInternal.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

const POPValueType supportedVelocityTypes[6] = { kPOPValuePoint, kPOPValueInteger, kPOPValueFloat, kPOPValueRect, kPOPValueSize, kPOPValueEdgeInsets };

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

- (id)reversedVelocity
{
  id reversedVelocity = nil;

  POPValueType velocityType = POPSelectValueType(self.originalVelocity, supportedVelocityTypes, POP_ARRAY_COUNT(supportedVelocityTypes));
  if (velocityType == kPOPValueFloat) {
#if CGFLOAT_IS_DOUBLE
    CGFloat originalVelocityFloat = [(NSNumber *)self.originalVelocity doubleValue];
#else
    CGFloat originalVelocityFloat = [(NSNumber *)self.originalVelocity floatValue];
#endif
    NSNumber *negativeOriginalVelocityNumber = @(-originalVelocityFloat);
    reversedVelocity = negativeOriginalVelocityNumber;
  } else if (velocityType == kPOPValueInteger) {
    NSInteger originalVelocityInteger = [(NSNumber *)self.originalVelocity integerValue];
    NSNumber *negativeOriginalVelocityNumber = @(-originalVelocityInteger);
    reversedVelocity = negativeOriginalVelocityNumber;
  } else if (velocityType == kPOPValuePoint) {
    CGPoint originalVelocityPoint = [self.originalVelocity CGPointValue];
    CGPoint negativeOriginalVelocityPoint = CGPointMake(-originalVelocityPoint.x, -originalVelocityPoint.y);
    reversedVelocity = [NSValue valueWithCGPoint:negativeOriginalVelocityPoint];
  } else if (velocityType == kPOPValueRect) {
    CGRect originalVelocityRect = [self.originalVelocity CGRectValue];
    CGRect negativeOriginalVelocityRect = CGRectMake(-originalVelocityRect.origin.x, -originalVelocityRect.origin.y, -originalVelocityRect.size.width, -originalVelocityRect.size.height);
    reversedVelocity = [NSValue valueWithCGRect:negativeOriginalVelocityRect];
  } else if (velocityType == kPOPValueSize) {
    CGSize originalVelocitySize = [self.originalVelocity CGSizeValue];
    CGSize negativeOriginalVelocitySize = CGSizeMake(-originalVelocitySize.width, -originalVelocitySize.height);
    reversedVelocity = [NSValue valueWithCGSize:negativeOriginalVelocitySize];
  } else if (velocityType == kPOPValueEdgeInsets) {
#if TARGET_OS_IPHONE
    UIEdgeInsets originalVelocityInsets = [self.originalVelocity UIEdgeInsetsValue];
    UIEdgeInsets negativeOriginalVelocityInsets = UIEdgeInsetsMake(-originalVelocityInsets.top, -originalVelocityInsets.left, -originalVelocityInsets.bottom, -originalVelocityInsets.right);
    reversedVelocity = [NSValue valueWithUIEdgeInsets:negativeOriginalVelocityInsets];
#endif
  }

  return reversedVelocity;
}

- (id)originalVelocity
{
  return POPBox(__state->originalVelocityVec, __state->valueType);
}

- (id)velocity
{
  return POPBox(__state->velocityVec, __state->valueType);
}

- (void)setVelocity:(id)aValue
{
  POPValueType valueType = POPSelectValueType(aValue, supportedVelocityTypes, POP_ARRAY_COUNT(supportedVelocityTypes));
  if (valueType != kPOPValueUnknown) {
    VectorRef vec = POPUnbox(aValue, __state->valueType, __state->valueCount, YES);
    VectorRef origVec = POPUnbox(aValue, __state->valueType, __state->valueCount, YES);

    if (!vec_equal(vec, __state->velocityVec)) {
      __state->velocityVec = vec;
      __state->originalVelocityVec = origVec;

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
  } else {
    __state->velocityVec = NULL;
    NSLog(@"Invalid velocity value for the decayAnimation: %@", aValue);
  }
}

#pragma mark - Utility

- (void)_ensureComputedProperties
{
  if (NULL == __state->toVec) {
    __state->computeDuration();
    __state->computeToValue();
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

  if (0 != self.duration) {
    [s appendFormat:@"; duration = %f", self.duration];
  }

  if (__state->deceleration) {
    [s appendFormat:@"; deceleration = %f", __state->deceleration];
  }
}

@end
