/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/QuartzCore.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>

#import <pop/POP.h>
#import <pop/POPAnimatorPrivate.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"

@interface POPDecayAnimationTests : POPBaseAnimationTests
@end

@implementation POPDecayAnimationTests

static NSString *animationKey = @"key";
static const CGFloat epsilon = 0.0001f;

- (POPDecayAnimation *)_positionAnimation
{
  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPosition];
  anim.fromValue = [NSValue valueWithCGPoint:CGPointZero];
  anim.velocity = [NSValue valueWithCGPoint:CGPointMake(7223.021, 7223.021)];
  anim.deceleration = 0.998000;
  return anim;
}

- (POPDecayAnimation *)_positionXAnimation
{
  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionX];
  anim.fromValue = @0.;
  anim.velocity = @7223.021;
  anim.deceleration = 0.998000;
  return anim;
}

- (POPDecayAnimation *)_positionYAnimation
{
  POPDecayAnimation *anim = self._positionXAnimation;
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionY];
  return anim;
}

- (void)testConvergence
{
  POPAnimatable *circle = [POPAnimatable new];
  POPDecayAnimation *anim = self._positionXAnimation;

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 10.0, 1.0/60.0);
  [tracer stop];

  // did reach to value
  POPAnimationValueEvent *didReachToEvent = [[tracer eventsWithType:kPOPAnimationEventDidReachToValue] lastObject];
  XCTAssertEqualObjects(didReachToEvent.value, anim.toValue, @"unexpected did reach to event: %@ anim:%@", didReachToEvent, anim);

  // finished
  POPAnimationValueEvent *stopEvent = [[tracer eventsWithType:kPOPAnimationEventDidStop] lastObject];
  XCTAssertEqualObjects(stopEvent.value, @YES, @"unexpected stop event %@", stopEvent);

  // all write values monotonically increasing
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  POPAnimationValueEvent *lastWriteEvent = nil;
  for (POPAnimationValueEvent *writeEvent in writeEvents) {
    if (lastWriteEvent) {
      NSComparisonResult result = [lastWriteEvent.value compare:writeEvent.value];
      XCTAssertTrue(NSOrderedAscending == result || NSOrderedSame == result, @"write event values not monotonically increasing current:%@ last:%@ all:%@", writeEvent, lastWriteEvent, writeEvents);
    }
    lastWriteEvent = writeEvent;
  }

  // convergence threshold
  NSUInteger toValueFrameCount = POPAnimationCountLastEventValues(writeEvents, anim.toValue, anim.property.threshold);
  XCTAssertTrue(toValueFrameCount <= kPOPAnimationConvergenceMaxFrameCount, @"unexpected convergence; toValueFrameCount: %lu", (unsigned long)toValueFrameCount);
}

- (void)testConvergenceNegativeVelocity
{
  POPAnimatable *circle = [POPAnimatable new];
  POPDecayAnimation *anim = self._positionXAnimation;
  anim.velocity = @-7223.021;

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 10.0, 1.0/60.0);
  [tracer stop];

  // did reach to value
  POPAnimationValueEvent *didReachToEvent = [[tracer eventsWithType:kPOPAnimationEventDidReachToValue] lastObject];
  XCTAssertEqualObjects(didReachToEvent.value, anim.toValue, @"unexpected did reach to event: %@ anim:%@", didReachToEvent, anim);

  // finished
  POPAnimationValueEvent *stopEvent = [[tracer eventsWithType:kPOPAnimationEventDidStop] lastObject];
  XCTAssertEqualObjects(stopEvent.value, @YES, @"unexpected stop event %@", stopEvent);

  // all write values monotonically increasing
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  POPAnimationValueEvent *lastWriteEvent = nil;
  for (POPAnimationValueEvent *writeEvent in writeEvents) {
    if (lastWriteEvent) {
      NSComparisonResult result = [lastWriteEvent.value compare:writeEvent.value];
      XCTAssertTrue(NSOrderedDescending == result || NSOrderedSame == result, @"write event values not monotonically decreasing current:%@ last:%@ all:%@", writeEvent, lastWriteEvent, writeEvents);
    }
    lastWriteEvent = writeEvent;
  }

  // convergence threshold
  NSUInteger toValueFrameCount = POPAnimationCountLastEventValues(writeEvents, anim.toValue, anim.property.threshold);
  XCTAssertTrue(toValueFrameCount <= kPOPAnimationConvergenceMaxFrameCount, @"unexpected convergence; toValueFrameCount: %lu", (unsigned long)toValueFrameCount);
}

- (void)test2DConvergence
{
  POPDecayAnimation *animX = self._positionXAnimation;
  POPDecayAnimation *animY = self._positionYAnimation;
  XCTAssertEqual(animX.duration, animY.duration, @"unexpected durations animX:%@ animY:%@", animX, animY);
  XCTAssertEqualObjects(animX.toValue, animY.toValue, @"unexpected toValue animX:%@ animY:%@", animX, animY);

  POPDecayAnimation *anim = self._positionAnimation;
  CFTimeInterval duration = anim.duration;
  XCTAssertEqualWithAccuracy(animX.duration, duration, epsilon, @"unexpected durations animX:%@ anim:%@", animX, anim);
  XCTAssertEqualObjects(animX.toValue, @([anim.toValue CGPointValue].x), @"unexpected toValue animX:%@ anim:%@", animX, anim);

  POPAnimatable *circle = [POPAnimatable new];
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 10.0, 1.0/60.0);
  [tracer stop];

  // did reach to value
  POPAnimationValueEvent *didReachToEvent = [[tracer eventsWithType:kPOPAnimationEventDidReachToValue] lastObject];
  XCTAssertEqualObjects(didReachToEvent.value, anim.toValue, @"unexpected did reach to event: %@ anim:%@", didReachToEvent, anim);

  // finished
  POPAnimationValueEvent *stopEvent = [[tracer eventsWithType:kPOPAnimationEventDidStop] lastObject];
  XCTAssertEqualObjects(stopEvent.value, @YES, @"unexpected stop event %@", stopEvent);

  // increase X velocity
  anim.velocity = [NSValue valueWithCGPoint:CGPointMake(7223.021 + 1000, 7223.021)];
  XCTAssertTrue(anim.duration > duration, @"unexpected duration expected:%f anim:%@", duration, anim);

  // increase Y velocity
  anim.velocity = [NSValue valueWithCGPoint:CGPointMake(7223.021, 7223.021 + 1000)];
  XCTAssertTrue(anim.duration > duration, @"unexpected duration expected:%f anim:%@", duration, anim);
}

- (void)testRemovedOnCompletionNoStartStopBasics
{
  static NSString *animationKey = @"key";

  CALayer *layer = self.layer1;
  POPAnimation *anim = self._positionXAnimation;
  POPAnimationTracer *tracer = anim.tracer;
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // cleanup
  [layer pop_removeAllAnimations];

  // configure animation
  anim.removedOnCompletion = NO;
  anim.delegate = delegate;

  __block BOOL completionBlock = NO;
  __block BOOL completionBlockFinished = NO;
  anim.completionBlock = ^(POPAnimation *a, BOOL finished) {
    completionBlock = YES;
    completionBlockFinished = finished;
  };

  // start tracer
  [tracer start];

  // expect start and stopped
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  [layer pop_addAnimation:anim forKey:animationKey];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 20.0, 1.0/60.0);
  NSArray *allEvents = tracer.allEvents;

  // verify delegate
  [delegate verify];
  XCTAssertTrue(completionBlock, @"completion block did not execute %@", allEvents);
  XCTAssertTrue(completionBlockFinished, @"completion block did not finish %@", allEvents);

  // assert animation has not been removed
  XCTAssertTrue(anim == [layer pop_animationForKey:animationKey], @"expected animation on layer animations:%@", [layer pop_animationKeys]);
}

- (void)testRemovedOnCompletionNoContinuations
{
  static NSString *animationKey = @"key";
  static NSArray *velocities = @[@50.0, @100.0, @20.0, @80.0];
  static NSArray *durations = @[@2.0, @0.5, @0.5, @2.0];

  CALayer *layer = self.layer1;
  POPDecayAnimation *anim = self._positionXAnimation;
  POPAnimationTracer *tracer = anim.tracer;
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // cleanup
  [layer pop_removeAllAnimations];

  // configure animation
  anim.removedOnCompletion = NO;
  anim.delegate = delegate;

  // start tracer
  [tracer start];

  __block CFTimeInterval beginTime;
  __block BOOL completionBlock = NO;
  __block BOOL completionBlockFinished = NO;

  [velocities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *ptrStop) {
    anim.velocity = obj;

    if (0 == idx) {
      [tracer reset];

      // starts and stops
      [[delegate expect] pop_animationDidStart:anim];
      [[delegate expect] pop_animationDidStop:anim finished:YES];

      anim.completionBlock = ^(POPAnimation *a, BOOL finished) {
        completionBlock = YES;
        completionBlockFinished = finished;
      };

      [layer pop_addAnimation:anim forKey:animationKey];

      beginTime = self.beginTime;
      CFTimeInterval dt = [durations[idx] doubleValue];
      POPAnimatorRenderDuration(self.animator, beginTime, dt, 1.0/60.0);
      beginTime += dt;

      NSArray *allEvents = tracer.allEvents;
      NSArray *didReachEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];

      // verify delegate
      [delegate verify];
      XCTAssertTrue(1 == didReachEvents.count, @"unexpected didReachEvents %@", didReachEvents);
      XCTAssertTrue(completionBlock, @"completion block did not execute %@", allEvents);
      XCTAssertTrue(completionBlockFinished, @"completion block did not finish %@", allEvents);
    } else if (velocities.count - 1 == idx) {
      // continue stoped animation
      [tracer reset];
      completionBlock = NO;
      completionBlockFinished = NO;
      [[delegate expect] pop_animationDidStop:anim finished:YES];

      CFTimeInterval dt = [durations[idx] doubleValue];
      POPAnimatorRenderDuration(self.animator, beginTime, dt, 1.0/60.0);
      beginTime += dt;

      NSArray *allEvents = tracer.allEvents;
      NSArray *didReachEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];

      // verify delegate
      [delegate verify];
      XCTAssertTrue(1 == didReachEvents.count, @"unexpected didReachEvents %@", didReachEvents);
      XCTAssertTrue(completionBlock, @"completion block did not execute %@", allEvents);
      XCTAssertTrue(completionBlockFinished, @"completion block did not finish %@", allEvents);
    } else {
      // continue stoped (idx = 1) or started animation
      if (1 == idx) {
        [[delegate expect] pop_animationDidStart:anim];
      }

      // reset state
      [tracer reset];
      completionBlock = NO;
      completionBlockFinished = NO;

      CFTimeInterval dt = [durations[idx] doubleValue];
      POPAnimatorRenderDuration(self.animator, beginTime, dt, 1.0/60.0);
      beginTime += dt;

      NSArray *allEvents = tracer.allEvents;
      NSArray *didReachEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];

      // verify delegate
      [delegate verify];
      XCTAssertTrue(0 == didReachEvents.count, @"unexpected didReachEvents %@", didReachEvents);
      XCTAssertFalse(completionBlock, @"completion block did not execute %@ %@", anim, allEvents);
      XCTAssertFalse(completionBlockFinished, @"completion block did not finish %@ %@", anim, allEvents);
    }

    // assert animation has not been removed
    XCTAssertTrue(anim == [layer pop_animationForKey:animationKey], @"expected animation on layer animations:%@", [layer pop_animationKeys]);
  }];
}

- (void)testNoOperationAnimation
{
  const CGPoint initialValue = CGPointMake(100, 100);

  CALayer *layer = self.layer1;
  layer.position = initialValue;
  [layer pop_removeAllAnimations];

  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPosition];

  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  anim.delegate = delegate;

  // starts and stops
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  [layer pop_addAnimation:anim forKey:animationKey];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 5, 1.0/60.0);

  // verify delegate
  [delegate verify];

  // verify number values
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  for (POPAnimationValueEvent *writeEvent in writeEvents) {
    XCTAssertEqualObjects(writeEvent.value, [NSValue valueWithCGPoint:initialValue], @"unexpected write event:%@ anim:%@", writeEvent, anim);
  }
}

- (void)testContinuation
{
  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPositionX];
  anim.fromValue = @0.0;
  anim.velocity = @1000.0;

  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  anim.delegate = delegate;
  [[delegate expect] pop_animationDidStart:anim];

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = self.layer1;
  [layer pop_addAnimation:anim forKey:animationKey];

  // run animation, not till completion
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 1.0/60.0);
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  [tracer reset];

  // verify start delegation
  [delegate verify];

  // update velocity of active animation
  anim.velocity = @1000.0;
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  // run animation some more
  POPAnimatorRenderDuration(self.animator, self.beginTime + 1, 4, 1.0/60.0);
  NSArray *moreWriteEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];

  // verify stop delegation
  [delegate verify];

  // compare event values
  POPAnimationValueEvent *firstEvent = [writeEvents firstObject];
  POPAnimationValueEvent *lastEvent = [writeEvents lastObject];
  POPAnimationValueEvent *firstMoreEvent = [moreWriteEvents firstObject];
  XCTAssertTrue(NSOrderedAscending == [firstEvent.value compare:lastEvent.value]
               && NSOrderedAscending == [lastEvent.value compare:firstMoreEvent.value], @"write event values not monotonically increasing %@ %@ %@", firstEvent, lastEvent, firstMoreEvent);
}

- (void)testRectSupport
{
  const CGRect fromRect = CGRectMake(0, 0, 0, 0);

  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
  anim.fromValue = [NSValue valueWithCGRect:fromRect];
  anim.velocity = [NSValue valueWithCGRect:CGRectMake(100, 100, 1000, 1000)];
  
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  anim.delegate = delegate;

  // expect start and stop to be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  // start tracer
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = self.layer1;
  [layer pop_addAnimation:anim forKey:animationKey];

  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);
  
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];

  // verify delegate
  [delegate verify];

  POPAnimationValueEvent *lastEvent = [writeEvents lastObject];
  CGRect lastRect = [lastEvent.value CGRectValue];
  
  XCTAssertTrue(!CGRectEqualToRect(fromRect, lastRect), @"unexpected last rect value: %@", lastEvent);
  XCTAssertTrue(lastRect.origin.x == lastRect.origin.y && lastRect.size.width == lastRect.size.height && lastRect.origin.x < lastRect.size.width, @"unexpected last rect value: %@", lastEvent);
}

#if TARGET_OS_IPHONE
- (void)testEdgeInsetsSupport
{
  const UIEdgeInsets fromEdgeInsets = UIEdgeInsetsZero;
  const UIEdgeInsets velocityEdgeInsets = UIEdgeInsetsMake(100, 100, 1000, 1000);

  POPDecayAnimation *anim = [POPDecayAnimation animation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPScrollViewContentInset];
  anim.fromValue = [NSValue valueWithUIEdgeInsets:fromEdgeInsets];
  anim.velocity = [NSValue valueWithUIEdgeInsets:velocityEdgeInsets];

  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  anim.delegate = delegate;

  // expect start and stop to be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  // start tracer
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  id scrollView = [OCMockObject niceMockForClass:[UIScrollView class]];
  [scrollView pop_addAnimation:anim forKey:nil];

  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);

  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];

  // verify delegate
  [delegate verify];

  POPAnimationValueEvent *lastEvent = [writeEvents lastObject];
  UIEdgeInsets lastEdgeInsets = [lastEvent.value UIEdgeInsetsValue];

  XCTAssertTrue(!UIEdgeInsetsEqualToEdgeInsets(fromEdgeInsets, lastEdgeInsets), @"unexpected last edge insets value: %@", lastEvent);
  XCTAssertTrue(lastEdgeInsets.top == lastEdgeInsets.left && lastEdgeInsets.bottom == lastEdgeInsets.right && lastEdgeInsets.top < lastEdgeInsets.bottom, @"unexpected last edge insets value: %@", lastEvent);
}
#endif

- (void)testEndValueOnReuse
{
  POPAnimatable *circle = [POPAnimatable new];
  POPDecayAnimation *anim = self._positionXAnimation;
  
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];
  
  // read out to value
  CGFloat toValue = [anim.toValue floatValue];
  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 5.0, 1.0/60.0);

  NSArray *stopEvent = [tracer eventsWithType:kPOPAnimationEventDidStop];
  XCTAssertTrue(1 == stopEvent.count, @"unexpected events:%@", tracer.allEvents);

  CGFloat lastValue = [[(POPAnimationValueEvent *)tracer.writeEvents.lastObject value] floatValue];
  XCTAssertEqualWithAccuracy(toValue, lastValue, 0.5, @"expected:%f actual event:%@", lastValue, tracer.writeEvents.lastObject);
  // update animation
  anim.fromValue = @([anim.toValue floatValue] - 100);
  anim.velocity = @(5000.);

  // and reuse
  [tracer reset];
  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 5.0, 1.0/60.0);

  // verify decayed passed initial toValue
  lastValue = [[(POPAnimationValueEvent *)tracer.writeEvents.lastObject value] floatValue];
  XCTAssertTrue(lastValue > toValue, @"unexpected last value:%f", lastValue);
}

- (void)testComputedProperties
{
  POPDecayAnimation *anim = [POPDecayAnimation animationWithPropertyNamed:kPOPLayerPositionX];
  
  // set velocity, test duration
  anim.velocity = @(100);
  CGFloat d1 = anim.duration;
  XCTAssertTrue(d1 > 0, @"unexpected duration %@", anim);
  
  // set velocity, test duration
  anim.velocity = @(1000);
  CGFloat d2 = anim.duration;
  XCTAssertTrue(d2 > d1, @"unexpected duration %@", anim);

  // set from value, test to value
  anim.fromValue = @(0);
  CGFloat p1 = [anim.toValue floatValue];
  XCTAssertTrue(p1 > [anim.fromValue floatValue], @"unexpected to value %@", anim);
  
  // set from value, test to value
  anim.fromValue = @(10000);
  CGFloat p2 = [anim.toValue floatValue];
  XCTAssertTrue(p2 > [anim.fromValue floatValue] && p2 > p1, @"unexpected to value %@", anim);
}

@end
