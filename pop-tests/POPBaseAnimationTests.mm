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

#import <pop/POP.h>
#import <pop/POPAnimatorPrivate.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPAnimationInternal.h"

@implementation POPBaseAnimationTests
{
  CALayer *_layer1;
  CALayer *_layer2;
  POPAnimator *_animator;
  CFTimeInterval _beginTime;
  POPAnimatableProperty *_radiusProperty;
  id delegate;
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

- (void)testCopyingSucceedsForConcreteAnimation:(POPAnimation *)anim
{
  POPAnimation *copy = [anim copy];
  
  XCTAssertEqualObjects(copy.name, anim.name, @"expected equality; value1:%@ value2:%@", copy.name, anim.name);
  XCTAssertEqual(copy.beginTime, anim.beginTime, @"expected equality; value1:%@ value2:%@", @(copy.beginTime), @(anim.beginTime));
  XCTAssertEqualObjects(copy.delegate, anim.delegate, @"expected equality; value1:%@ value2:%@", copy.delegate, anim.delegate);
  XCTAssertEqualObjects(copy.animationDidStartBlock, anim.animationDidStartBlock, @"expected equality; value1:%@ value2:%@", copy.animationDidStartBlock, anim.animationDidStartBlock);
  XCTAssertEqualObjects(copy.animationDidReachToValueBlock, anim.animationDidReachToValueBlock, @"expected equality; value1:%@ value2:%@", copy.animationDidReachToValueBlock, anim.animationDidReachToValueBlock);
  XCTAssertEqualObjects(copy.completionBlock, anim.completionBlock, @"expected equality; value1:%@ value2:%@", copy.completionBlock, anim.completionBlock);
  XCTAssertEqualObjects(copy.animationDidApplyBlock, anim.animationDidApplyBlock, @"expected equality; value1:%@ value2:%@", copy.animationDidApplyBlock, anim.animationDidApplyBlock);
  XCTAssertEqual(copy.removedOnCompletion, anim.removedOnCompletion, @"expected equality; value1:%@ value2:%@", @(copy.removedOnCompletion), @(anim.removedOnCompletion));
  XCTAssertEqual(copy.autoreverses, anim.autoreverses, @"expected equality; value1:%@ value2:%@", @(copy.autoreverses), @(anim.autoreverses));
  XCTAssertEqual(copy.repeatCount, anim.repeatCount, @"expected equality; value1:%@ value2:%@", @(copy.repeatCount), @(anim.repeatCount));
  XCTAssertEqual(copy.repeatForever, anim.repeatForever, @"expected equality; value1:%@ value2:%@", @(copy.repeatForever), @(anim.repeatForever));
}

- (void)testCopyingSucceedsForConcretePropertyAnimation:(POPPropertyAnimation *)anim
{
  [self testCopyingSucceedsForConcreteAnimation:anim];
  
  POPPropertyAnimation *copy = [anim copy];
  
  XCTAssertEqualObjects(copy.fromValue, anim.fromValue, @"expected equality; value1:%@ value2:%@", copy.fromValue, anim.fromValue);
  XCTAssertEqualObjects(copy.toValue, anim.toValue, @"expected equality; value1:%@ value2:%@", copy.toValue, anim.toValue);
  XCTAssertEqual(copy.roundingFactor, anim.roundingFactor, @"expected equality; value1:%@ value2:%@", @(copy.roundingFactor), @(anim.roundingFactor));
  XCTAssertEqual(copy.clampMode, anim.clampMode, @"expected equality; value1:%@ value2:%@", @(copy.clampMode), @(anim.clampMode));
  XCTAssertEqual(copy.additive, anim.additive, @"expected equality; value1:%@ value2:%@", @(copy.additive), @(anim.additive));
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

void configureConcreteAnimation(POPAnimation *anim)
{
  static id delegate = [NSObject new];
  
  anim.name = @"pop_animation_copy_test";
  anim.beginTime = 1.234;
  anim.delegate = delegate; // dummy delegate
  anim.animationDidStartBlock = ^(POPAnimation *a){ NSLog(@"Animation Did Start"); };
  anim.animationDidReachToValueBlock = ^(POPAnimation *a){ NSLog(@"Animation Did Reach To Value"); };
  anim.completionBlock = ^(POPAnimation *a, BOOL finished){ NSLog(@"Animation Finished"); };
  anim.animationDidApplyBlock = ^(POPAnimation *){ NSLog(@"Animation Applied"); };
  anim.removedOnCompletion = NO; // not default
  anim.autoreverses = YES; // not default
  anim.repeatCount = 42;
  anim.repeatForever = YES; // not default
}

void configureConcretePropertyAnimation(POPPropertyAnimation *anim)
{
  configureConcreteAnimation(anim);
  
  // Decay animations don't use fromValue, so setting it here causes issues.
  if (![anim isMemberOfClass:[POPDecayAnimation class]]) {
    
    anim.fromValue = @(12345);
  }
  
  anim.toValue = @(77888);
  anim.roundingFactor = 0.257;
  anim.clampMode = 87;
  anim.additive = YES; // not default
}
