/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPBaseAnimationTests.h"

#import <QuartzCore/QuartzCore.h>

#import <OCMock/OCMock.h>

#import <POP/POP.h>
#import <POP/POPAnimatorPrivate.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"

@implementation POPBaseAnimationTests
{
  CALayer *_layer1;
  CALayer *_layer2;
  POPAnimator *_animator;
  CFTimeInterval _beginTime;
  POPAnimatableProperty *_radiusProperty;
}
@synthesize layer1 = _layer1;
@synthesize layer2 = _layer2;
@synthesize animator = _animator;
@synthesize beginTime = _beginTime;
@synthesize radiusProperty = _radiusProperty;

- (void)setUp
{
  [super setUp];
  _layer1 = [[CALayer alloc] init];
  _layer2 = [[CALayer alloc] init];
  _animator = [POPAnimator sharedAnimator];
  _radiusProperty = [POPAnimatableProperty propertyWithName:@"radius" initializer:^(POPMutableAnimatableProperty *prop){
    prop.readBlock = ^(POPAnimatable *obj, CGFloat values[]) {
      values[0] = [obj radius];
    };
    prop.writeBlock = ^(POPAnimatable *obj, const CGFloat values[]) {
      obj.radius = values[0];
    };
    prop.threshold = 0.01;
  }];
  _beginTime = CACurrentMediaTime();
  _animator.beginTime = _beginTime;
}

@end

NSUInteger kPOPAnimationConvergenceMaxFrameCount = 12; // 12 frames, ~200ms at 1/60fps, the user perseption threshold

NSUInteger POPAnimationCountLastEventValues(NSArray *events, NSNumber *value, float epsilon)
{
  __block NSUInteger count = 0;
  [events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(POPAnimationValueEvent *event, NSUInteger idx, BOOL *ptrStop) {

    BOOL match = 0 == epsilon ? [event.value isEqualToValue:value] : fabsf([event.value floatValue] - [value floatValue]) < epsilon;
    if (!match) {
      *ptrStop = YES;
    } else {
      count++;
    }
  }];
  return count;
}

BOOL POPAnimationEventsContainValue(NSArray *events, NSNumber *value)
{
  for (POPAnimationValueEvent *event in events) {
    if ([event.value isEqual:value]) {
      return YES;
    }
  }
  return NO;
}

