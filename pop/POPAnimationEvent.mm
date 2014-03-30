/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationEvent.h"
#import "POPAnimationEventInternal.h"

static NSString *stringFromType(POPAnimationEventType aType)
{
  switch (aType) {
    case kPOPAnimationEventPropertyRead:
      return @"read";
    case kPOPAnimationEventPropertyWrite:
      return @"write";
    case kPOPAnimationEventToValueUpdate:
      return @"toValue";
    case kPOPAnimationEventFromValueUpdate:
      return @"fromValue";
    case kPOPAnimationEventVelocityUpdate:
      return @"velocity";
    case kPOPAnimationEventSpeedUpdate:
      return @"speed";
    case kPOPAnimationEventBouncinessUpdate:
      return @"bounciness";
    case kPOPAnimationEventFrictionUpdate:
      return @"friction";
    case kPOPAnimationEventMassUpdate:
      return @"mass";
    case kPOPAnimationEventTensionUpdate:
      return @"tension";
    case kPOPAnimationEventDidStart:
      return @"didStart";
    case kPOPAnimationEventDidStop:
      return @"didStop";
    case kPOPAnimationEventDidReachToValue:
      return @"didReachToValue";
    default:
      return nil;
  }
}

@implementation POPAnimationEvent

- (instancetype)initWithType:(POPAnimationEventType)aType time:(CFTimeInterval)aTime
{
  self = [super init];
  if (nil != self) {
    _type = aType;
    _time = aTime;
  }
  return self;
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"<POPAnimationEvent:%f; type = %@", _time, stringFromType(_type)];
  [self _appendDescription:s];
  [s appendString:@">"];
  return s;
}

// subclass override
- (void)_appendDescription:(NSMutableString *)s
{
  if (0 != _animationDescription.length) {
    [s appendFormat:@"; animation = %@", _animationDescription];
  }
}

@end

@implementation POPAnimationValueEvent

- (instancetype)initWithType:(POPAnimationEventType)aType time:(CFTimeInterval)aTime value:(id)aValue
{
  self = [self initWithType:aType time:aTime];
  if (nil != self) {
    _value = aValue;
  }
  return self;
}

- (void)_appendDescription:(NSMutableString *)s
{
  [super _appendDescription:s];

  if (nil != _value) {
    [s appendFormat:@"; value = %@", _value];
  }

  if (nil != _velocity) {
    [s appendFormat:@"; velocity = %@", _velocity];
  }
}

@end
