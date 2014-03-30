/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/QuartzCore.h>

#import <OCMock/OCMock.h>
#import <SenTestingKit/SenTestingKit.h>

#import <POP/POP.h>
#import <POP/POPAnimatorPrivate.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"

@interface POPEaseInEaseOutAnimationTests : POPBaseAnimationTests
@end

@implementation POPEaseInEaseOutAnimationTests

- (void)testCompletion
{
  // animation
  // the default from, to and bounciness values are used
  POPBasicAnimation *anim = [POPBasicAnimation easeInEaseOutAnimation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerScaleXY];
  anim.fromValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
  anim.toValue = [NSValue valueWithCGPoint:CGPointMake(0.97, 0.97)];

  // delegate
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // expect start, progress & stop to all be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  anim.delegate = delegate;

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:@"key"];

  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @0.1, @0.2, @0.4]);
  [delegate verify];
}

- (void)testRectSupport
{
  const CGRect fromRect = CGRectMake(0, 0, 0, 0);
  const CGRect toRect = CGRectMake(100, 200, 200, 400);

  POPBasicAnimation *anim = [POPBasicAnimation easeInEaseOutAnimation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
  anim.fromValue = [NSValue valueWithCGRect:fromRect];
  anim.toValue = [NSValue valueWithCGRect:toRect];
  
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  anim.delegate = delegate;
  
  // expect start and stop to be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];
  
  // start tracer
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];
  
  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:@""];
  
  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 1.0/60.0);
  
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  
  // verify delegate
  [delegate verify];
  
  POPAnimationValueEvent *lastEvent = [writeEvents lastObject];
  CGRect lastRect = [lastEvent.value CGRectValue];
  
  // verify last rect is to rect
  STAssertTrue(CGRectEqualToRect(lastRect, toRect), @"unexpected last rect value: %@", lastEvent);
}

@end
