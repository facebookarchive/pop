/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationTracer.h"

#import <QuartzCore/QuartzCore.h>

#import "POPAnimationEventInternal.h"
#import "POPAnimationInternal.h"
#import "POPSpringAnimation.h"

@implementation POPAnimationTracer
{
  __weak POPAnimation *_animation;
  POPAnimationState *_animationState;
  NSMutableArray *_events;
  BOOL _animationHasVelocity;
}

static POPAnimationEvent *create_event(POPAnimationTracer *self, POPAnimationEventType type, id value = nil, bool recordAnimation = false)
{
  bool useLocalTime = 0 != self->_animationState->startTime;
  CFTimeInterval time = useLocalTime
    ? self->_animationState->lastTime - self->_animationState->startTime
    : self->_animationState->lastTime;

  POPAnimationEvent *event;

  if (!value) {
    event = [[POPAnimationEvent alloc] initWithType:type time:time];
  } else {
    event = [[POPAnimationValueEvent alloc] initWithType:type time:time value:value];
    if (self->_animationHasVelocity) {
      [(POPAnimationValueEvent *)event setVelocity:[(POPSpringAnimation *)self->_animation velocity]];
    }
  }

  if (recordAnimation) {
    event.animationDescription = [self->_animation description];
  }

  return event;
}

- (id)initWithAnimation:(POPAnimation *)anAnim
{
  self = [super init];
  if (nil != self) {
    _animation = anAnim;
    _animationState = POPAnimationGetState(anAnim);
    _events = [[NSMutableArray alloc] initWithCapacity:50];
    _animationHasVelocity = [anAnim respondsToSelector:@selector(velocity)];
  }
  return self;
}

- (void)readPropertyValue:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventPropertyRead, aValue);
  [_events addObject:event];
}

- (void)writePropertyValue:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventPropertyWrite, aValue);
  [_events addObject:event];
}

- (void)updateToValue:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventToValueUpdate, aValue);
  [_events addObject:event];
}

- (void)updateFromValue:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventFromValueUpdate, aValue);
  [_events addObject:event];
}

- (void)updateVelocity:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventVelocityUpdate, aValue);
  [_events addObject:event];
}

- (void)updateSpeed:(float)aFloat
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventSpeedUpdate, @(aFloat));
  [_events addObject:event];
}

- (void)updateBounciness:(float)aFloat
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventBouncinessUpdate, @(aFloat));
  [_events addObject:event];
}

- (void)updateFriction:(float)aFloat
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventFrictionUpdate, @(aFloat));
  [_events addObject:event];
}

- (void)updateMass:(float)aFloat
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventMassUpdate, @(aFloat));
  [_events addObject:event];
}

- (void)updateTension:(float)aFloat
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventTensionUpdate, @(aFloat));
  [_events addObject:event];
}

- (void)didStart
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventDidStart, nil, true);
  [_events addObject:event];
}

- (void)didStop:(BOOL)finished
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventDidStop, @(finished), true);
  [_events addObject:event];

  if (_shouldLogAndResetOnCompletion) {
    NSLog(@"events:%@", self.allEvents);
    [self reset];
  }
}

- (void)didReachToValue:(id)aValue
{
  POPAnimationEvent *event = create_event(self, kPOPAnimationEventDidReachToValue, aValue);
  [_events addObject:event];
}

- (void)start
{
  POPAnimationState *s = POPAnimationGetState(_animation);
  s->tracing = true;
}

- (void)stop
{
  POPAnimationState *s = POPAnimationGetState(_animation);
  s->tracing = false;
}

- (void)reset
{
  [_events removeAllObjects];
}

- (NSArray *)allEvents
{
  return [_events copy];
}

- (NSArray *)writeEvents
{
  return [self eventsWithType:kPOPAnimationEventPropertyWrite];
}

- (NSArray *)eventsWithType:(POPAnimationEventType)aType
{
  NSMutableArray *array = [NSMutableArray array];
  for (POPAnimationEvent *event in _events) {
    if (aType == event.type) {
      [array addObject:event];
    }
  }
  return array;
}

@end
