/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPPropertyAnimationInternal.h"

@implementation POPPropertyAnimation

#pragma mark - Lifecycle

#undef __state
#define __state ((POPPropertyAnimationState *)_state)

- (void)_initState
{
  _state = new POPPropertyAnimationState(self);
}

#pragma mark - Properties

DEFINE_RW_FLAG(POPPropertyAnimationState, additive, isAdditive, setAdditive:);
DEFINE_RW_PROPERTY(POPPropertyAnimationState, roundingFactor, setRoundingFactor:, CGFloat);
DEFINE_RW_PROPERTY(POPPropertyAnimationState, clampMode, setClampMode:, NSUInteger);
DEFINE_RW_PROPERTY_OBJ(POPPropertyAnimationState, property, setProperty:, POPAnimatableProperty*, ((POPPropertyAnimationState*)_state)->updatedDynamicsThreshold(););
DEFINE_RW_PROPERTY_OBJ_COPY(POPPropertyAnimationState, progressMarkers, setProgressMarkers:, NSArray*, ((POPPropertyAnimationState*)_state)->updatedProgressMarkers(););

- (id)fromValue
{
  return POPBox(__state->fromVec, __state->valueType);
}

- (void)setFromValue:(id)aValue
{
  POPPropertyAnimationState *s = __state;
  VectorRef vec = POPUnbox(aValue, s->valueType, s->valueCount, YES);
  if (!vec_equal(vec, s->fromVec)) {
    s->fromVec = vec;

    if (s->tracing) {
      [s->tracer updateFromValue:aValue];
    }
  }
}

- (id)toValue
{
  return POPBox(__state->toVec, __state->valueType);
}

- (void)setToValue:(id)aValue
{
  POPPropertyAnimationState *s = __state;
  VectorRef vec = POPUnbox(aValue, s->valueType, s->valueCount, YES);

  if (!vec_equal(vec, s->toVec)) {
    s->toVec = vec;

    // invalidate to dependent state
    s->didReachToValue = false;
    s->distanceVec = NULL;

    if (s->tracing) {
      [s->tracer updateToValue:aValue];
    }

    // automatically unpause active animations
    if (s->active && s->paused) {
      s->setPaused(false);
    }
  }
}

- (id)currentValue
{
  return POPBox(__state->currentValue(), __state->valueType);
}

#pragma mark - Utility

- (void)_appendDescription:(NSMutableString *)s debug:(BOOL)debug
{
  [s appendFormat:@"; from = %@; to = %@", describe(__state->fromVec), describe(__state->toVec)];

  if (_state->active)
    [s appendFormat:@"; currentValue = %@", describe(__state->currentValue())];

  if (__state->velocityVec && 0 != __state->velocityVec->norm())
    [s appendFormat:@"; velocity = %@", describe(__state->velocityVec)];

  if (!self.removedOnCompletion)
    [s appendFormat:@"; removedOnCompletion = %@", POPStringFromBOOL(self.removedOnCompletion)];

  if (__state->progressMarkers)
    [s appendFormat:@"; progressMarkers = [%@]", [__state->progressMarkers componentsJoinedByString:@", "]];

  if (_state->active)
    [s appendFormat:@"; progress = %f", __state->progress];
}

- (BOOL)animationIsValidForObject:(id)obj andKey:(NSString *)key
{
    id type = [obj class];
    //Check property exist
    objc_property_t theProperty = class_getProperty(type, [key UTF8String]);
    if (!theProperty) {
        NSAssert(0x0 !=theProperty  , @"key (%@) for object (%@) doesn't exist !", key,obj);
        return NO;
    } else {
        
        // Check attributes and expected type
        const char *attributes = property_getAttributes(theProperty);
        
        if(strcmp(self.property.expectedPropertyAttributes, attributes) != 0) {
            NSString * propertyType = [NSString stringWithFormat:@"%s",attributes];
            const char * attributes = [[propertyType substringFromIndex:1] UTF8String];
            
            if(strcmp(self.property.expectedPropertyAttributes, attributes) != 0) {
                NSAssert(0 , @"key (%@) for object (%@) is not of the expected type !", key,obj);
                return NO;
            }
        }
    }
    
    return YES;
}

@end
