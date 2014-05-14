/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <SenTestingKit/SenTestingKit.h>

#import <OCMock/OCMock.h>
#import <POP/POPCustomAnimation.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"

static const CGFloat epsilon = 0.0001f;

@interface POPCustomAnimationTests : POPBaseAnimationTests
@end

@implementation POPCustomAnimationTests

- (void)testCallbackFinished
{
  static NSString * const key = @"key";
  static CFTimeInterval const timeInterval = 0.1;

  __block NSUInteger callbackCount = 0;
  
  // animation
  POPCustomAnimation *anim = [POPCustomAnimation animationWithBlock:^BOOL(id target, POPCustomAnimation *animation) {
    if (0 != callbackCount) {
      // validate elapsed time
      STAssertEqualsWithAccuracy(animation.elapsedTime, timeInterval, epsilon, @"expected elapsedTime:%f %@", timeInterval, animation);
    }

    // increment callback count
    callbackCount++;

    return callbackCount < 3;
  }];

  anim.beginTime = self.beginTime;
  
  // delegate
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  
  // expect start, progress & stop to all be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];
  [[delegate expect] pop_animationDidApply:anim];
  
  anim.delegate = delegate;

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];
  
  // layer
  id layer = [OCMockObject niceMockForClass:[CALayer class]];
  [layer pop_addAnimation:anim forKey:key];
  
  POPAnimatorRenderDuration(self.animator, self.beginTime + 0.1, 5, 0.1);
  STAssertTrue(callbackCount == 3, @"unexpected callbackCount:%d", callbackCount);
  
  NSArray *startEvents = [tracer eventsWithType:kPOPAnimationEventDidStart];
  STAssertTrue(1 == startEvents.count, @"unexpected startEvents count %@", startEvents);
  
  NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
  STAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);

  [layer verify];
  [delegate verify];
}

- (void)testCallbackCancelled
{
  static NSString * const key = @"key";
  static CFTimeInterval const timeInterval = 0.1;
  
  __block NSUInteger callbackCount = 0;
  
  // animation
  POPCustomAnimation *anim = [POPCustomAnimation animationWithBlock:^BOOL(id target, POPCustomAnimation *animation) {
    if (0 == callbackCount) {
      // validate elapsed time acruel
      STAssertEqualsWithAccuracy(animation.elapsedTime, 0., epsilon, @"expected elapsedTime:%f %@", timeInterval, animation);
    } else {
      // validate elapsed time acruel
      STAssertEqualsWithAccuracy(animation.elapsedTime, timeInterval, epsilon, @"expected elapsedTime:%f %@", timeInterval, animation);
    }
    
    // increment callback count
    callbackCount++;
    
    if (callbackCount == 3) {
      [target pop_removeAnimationForKey:key];
    }
    
    return callbackCount < 3;
  }];
  
  anim.beginTime = self.beginTime;
  
  // delegate
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  
  // expect start, progress & stop to all be called
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:NO];
  [[delegate expect] pop_animationDidApply:anim];
  
  anim.delegate = delegate;
  
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  // layer
  id layer = [OCMockObject niceMockForClass:[CALayer class]];
  [layer pop_addAnimation:anim forKey:key];
  
  POPAnimatorRenderDuration(self.animator, self.beginTime + 0.1, 5, 0.1);
  STAssertTrue(callbackCount == 3, @"unexpected callbackCount:%d", callbackCount);

  NSArray *startEvents = [tracer eventsWithType:kPOPAnimationEventDidStart];
  STAssertTrue(1 == startEvents.count, @"unexpected startEvents count %@", startEvents);
  
  NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
  STAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);
  
  [layer verify];
  [delegate verify];
}

- (void)testAssociation
{
  static NSString * const key = @"key";
  
  __block id blockTarget = nil;
  
  POPCustomAnimation *anim = [POPCustomAnimation animationWithBlock:^(id target, POPCustomAnimation *animation) {
    blockTarget = target;
    return YES;
  }];

  id layer = [OCMockObject niceMockForClass:[CALayer class]];

  [layer pop_addAnimation:anim forKey:key];
  
  // verify animation & key
  STAssertTrue(anim == [layer pop_animationForKey:key], @"expected:%@ actual:%@", anim, [layer pop_animationForKey:key]);
  STAssertTrue([[layer pop_animationKeys] containsObject:key], @"expected:%@ actual:%@", key, [layer pop_animationKeys]);
  
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 0.1);

  STAssertEqualObjects(layer, blockTarget, @"expected:%@ actual:%@", layer, blockTarget);
  
  // remove animations
  [layer pop_removeAnimationForKey:key];

  // verify animation & key
  STAssertFalse(anim == [layer pop_animationForKey:key], @"expected:%@ actual:%@", nil, [layer pop_animationForKey:key]);
  STAssertFalse([[layer pop_animationKeys] containsObject:key], @"expected:%@ actual:%@", nil, [layer pop_animationKeys]);
}

@end
