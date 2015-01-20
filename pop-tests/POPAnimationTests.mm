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
#import <pop/POPAnimationPrivate.h>
#import <pop/POPAnimatorPrivate.h>

#import "POPAnimatable.h"
#import "POPAnimationRuntime.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"
#import "POPCGUtils.h"

using namespace POP;

@interface POPAnimation (TestExtensions)
@property (strong, nonatomic) NSString *sampleKey;
@end

@implementation POPAnimation (TestExtensions)
- (NSString *)sampleKey { return [self valueForUndefinedKey:@"sampleKey"]; }
- (void)setSampleKey:(NSString *)aValue { [self setValue:aValue forUndefinedKey:@"sampleKey"];}
@end

@interface POPAnimationTests : POPBaseAnimationTests
@end

@implementation POPAnimationTests

- (void)testOrneryAbstractClasses
{
  XCTAssertThrows([[POPAnimation alloc] init], @"should not be able to instiate abstract class");
  XCTAssertThrows([[POPPropertyAnimation alloc] init], @"should not be able to instiate abstract class");
}

- (void)testWithPropertyNamedConstruction
{
  POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
  POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
  XCTAssertTrue(anim.property == prop, @"expected:%@ actual:%@", prop, anim.property);
}

- (void)testAdditionRemoval
{
  CALayer *layer1 = self.layer1;
  CALayer *layer2 = self.layer2;
  [layer1 removeAllAnimations];
  [layer2 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  [layer1 pop_addAnimation:anim forKey:@"hello"];

  NSArray *keys = [layer1 pop_animationKeys];
  XCTAssertTrue(1 == keys.count);
  XCTAssertTrue([@"hello" isEqualToString:keys.lastObject]);

  [layer1 pop_removeAnimationForKey:@"hello"];
  XCTAssertTrue(0 == [layer1 pop_animationKeys].count);

  [layer1 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"hello"];
  [layer1 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"world"];
  [layer2 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"hello"];

  XCTAssertTrue(2 == [layer1 pop_animationKeys].count);
  XCTAssertTrue(1 == [layer2 pop_animationKeys].count);

  [layer1 pop_removeAllAnimations];
  XCTAssertTrue(0 == [layer1 pop_animationKeys].count);
  XCTAssertTrue(1 == [layer2 pop_animationKeys].count);
}

- (void)testStartStopDelegation
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // expect start, stop finished
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];
  anim.delegate = delegate;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);

  // verify expectations
  [delegate verify];
}

- (void)testAnimationValues
{
  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);

  // avoid fractional values; simplify verification
  anim.roundingFactor = 1.0;

  id layer = [OCMockObject niceMockForClass:[CALayer class]];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.25).cg_point()];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.5).cg_point()];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.75).cg_point()];
  [[layer expect] setPosition:[anim.toValue CGPointValue]];

  [layer pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 0.25);

  [layer verify];
}

- (void)testNoAutoreverseRepeatCount0
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.repeatCount = 0;
  anim.roundingFactor = 1.0;
  anim.autoreverses = NO;

  NSValue *originalToValue = anim.toValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 2.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKeyPath:@"position"], originalToValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalToValue);
}

- (void)testNoAutoreverseRepeatCount1
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.repeatCount = 1;
  anim.roundingFactor = 1.0;
  anim.autoreverses = NO;

  NSValue *originalToValue = anim.toValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKeyPath:@"position"], originalToValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalToValue);
}

- (void)testNoAutoreverseRepeatCount4
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.repeatCount = 4;
  anim.roundingFactor = 1.0;
  anim.autoreverses = NO;

  NSValue *originalToValue = anim.toValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 6.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKeyPath:@"position"], originalToValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalToValue);
}

- (void)testAutoreverseRepeatCount0
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.roundingFactor = 1.0;
  anim.autoreverses = YES;
  anim.repeatCount = 0;
  [anim.tracer start];

  NSValue *originalFromValue = anim.fromValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKey:@"position"], originalFromValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalFromValue);

  NSArray *autoreversedEvents = [anim.tracer eventsWithType:kPOPAnimationEventAutoreversed];
  XCTAssertTrue(1 == autoreversedEvents.count, @"unexpected autoreversed events %@", autoreversedEvents);

  anim.autoreverses = NO;
}

- (void)testAutoreverseRepeatCount1
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.roundingFactor = 1.0;
  anim.autoreverses = YES;
  anim.repeatCount = 1;
  [anim.tracer start];

  NSValue *originalFromValue = anim.fromValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKey:@"position"], originalFromValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalFromValue);

  NSArray *autoreversedEvents = [anim.tracer eventsWithType:kPOPAnimationEventAutoreversed];
  XCTAssertTrue(1 == autoreversedEvents.count, @"unexpected autoreversed events %@", autoreversedEvents);

  anim.autoreverses = NO;
}

- (void)testAutoreverseRepeatCount4
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.roundingFactor = 1.0;
  anim.autoreverses = YES;

  NSInteger repeatCount = 4;
  anim.repeatCount = repeatCount;
  [anim.tracer start];

  NSValue *originalFromValue = anim.fromValue;

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 9.0, 0.25); // animate longer than needed to verify animation has stopped in the appropriate place

  XCTAssertEqualObjects([layer1 valueForKey:@"position"], originalFromValue, @"expected equality; value1:%@ value2:%@", [layer1 valueForKey:@"position"], originalFromValue);

  NSArray *autoreversedEvents = [anim.tracer eventsWithType:kPOPAnimationEventAutoreversed];
  XCTAssertTrue((repeatCount * 2) - 1 == (int)autoreversedEvents.count, @"unexpected autoreversed events %@", autoreversedEvents);

  anim.autoreverses = NO;
}

- (void)testReAddition
{
  CALayer *layer1 = self.layer1;
  CALayer *layer2 = self.layer2;
  [layer1 removeAllAnimations];
  [layer2 removeAllAnimations];

  static NSString *key = @"key";

  POPAnimation *anim1, *anim2;
  id delegate1, delegate2;

  anim1 = FBTestLinearPositionAnimation(self.beginTime);
  delegate1 = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // expect start, stop not finished
  [[delegate1 expect] pop_animationDidStart:anim1];
  [[delegate1 expect] pop_animationDidStop:anim1 finished:NO];

  anim1.delegate = delegate1;
  [layer1 pop_addAnimation:anim1 forKey:key];

  anim2 = FBTestLinearPositionAnimation(self.beginTime);
  delegate2 = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // expect start, stop finished
  [[delegate2 expect] pop_animationDidStart:anim2];
  [[delegate2 expect] pop_animationDidStop:anim2 finished:YES];
  anim2.delegate = delegate2;

  // add with same key
  [layer1 pop_addAnimation:anim2 forKey:key];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);

  // verify expectations
  [delegate1 verify];
  [delegate2 verify];
}

- (void)testAnimationDidStartBlock
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // set animation did start block
  anim.animationDidStartBlock = ^(POPAnimation *a) {
    [delegate pop_animationDidStart:a];
  };

  [[delegate expect] pop_animationDidStart:anim];

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);
  [delegate verify];
}

- (void)testAnimationDidReachToValueBlock
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // set animation did reach to value block
  anim.animationDidReachToValueBlock = ^(POPAnimation *a) {
    [delegate pop_animationDidReachToValue:a];
  };

  [[delegate expect] pop_animationDidReachToValue:anim];

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);
  [delegate verify];
}

- (void)testCompletionBlock
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  anim.completionBlock = ^(POPAnimation *a, BOOL finished) {
    [delegate pop_animationDidStop:a finished:finished];
  };

  // test for unfinished completion
  [[delegate expect] pop_animationDidStop:anim finished:NO];

  [layer1 pop_addAnimation:anim forKey:@"key"];
  [layer1 pop_removeAllAnimations];
  [delegate verify];

  anim = FBTestLinearPositionAnimation(self.beginTime);
  delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // set completion block
  anim.completionBlock = ^(POPAnimation *a, BOOL finished) {
    [delegate pop_animationDidStop:a finished:finished];
  };

  // test for finished completion
  [[delegate expect] pop_animationDidStop:anim finished:YES];

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);
  [delegate verify];
}

- (void)testAnimationDidApplyBlock
{
  CALayer *layer1 = self.layer1;
  [layer1 removeAllAnimations];

  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  // set animation did apply block
  anim.animationDidApplyBlock = ^(POPAnimation *a) {
    [delegate pop_animationDidApply:a];
  };

  [[delegate expect] pop_animationDidApply:anim];

  [layer1 pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, @1.0]);
  [delegate verify];
}

- (void)testReuse
{
  NSValue *fromValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
  NSValue *toValue = [NSValue valueWithCGPoint:CGPointMake(200, 200)];
  CGFloat testProgress = 0.25;

  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  anim.fromValue = fromValue;
  anim.toValue = toValue;
  anim.roundingFactor = 1.0;

  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];
  anim.delegate = delegate;

  id layer = [OCMockObject niceMockForClass:[CALayer class]];

  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([fromValue CGPointValue]), Vector2r([toValue CGPointValue]), testProgress).cg_point()];
  [[layer expect] setPosition:[toValue CGPointValue]];

  [layer pop_addAnimation:anim forKey:@"key"];

  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, [NSNumber numberWithFloat:testProgress * anim.duration], [NSNumber numberWithFloat:anim.duration]]);
  [layer verify];
  [delegate verify];

  // new delegate & layer, same animation
  delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
  [[delegate expect] pop_animationDidStart:anim];
  [[delegate expect] pop_animationDidStop:anim finished:YES];
  anim.delegate = delegate;

  layer = [OCMockObject niceMockForClass:[CALayer class]];
  
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([fromValue CGPointValue]), Vector2r([toValue CGPointValue]), testProgress).cg_point()];
  [[layer expect] setPosition:[toValue CGPointValue]];

  [layer pop_addAnimation:anim forKey:@"key"];

  POPAnimatorRenderTimes(self.animator, self.beginTime, @[@0.0, [NSNumber numberWithFloat:testProgress * anim.duration], [NSNumber numberWithFloat:anim.duration]]);
  [layer verify];

  [delegate verify];
}

- (void)testCancelBeforeBegin
{
  POPAnimation *anim = FBTestLinearPositionAnimation(self.beginTime + 100000);
  [anim.tracer start];

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:@"key"];
  [layer pop_removeAllAnimations];

  NSArray *didStartEvents = [anim.tracer eventsWithType:kPOPAnimationEventDidStart];
  NSArray *didStopEvents = [anim.tracer eventsWithType:kPOPAnimationEventDidStop];
  XCTAssertTrue(1 == didStartEvents.count, @"unexpected start events %@", didStartEvents);
  XCTAssertTrue(1 == didStopEvents.count, @"unexpected stop events %@", didStopEvents);
}

- (void)testAddedKeys
{
  POPAnimation *anim = FBTestLinearPositionAnimation();
  anim.sampleKey = @"value";
  XCTAssertEqualObjects(anim.sampleKey, @"value", @"property value read should equal write");
}

- (void)testValueTypeResolution
{
  POPSpringAnimation *anim = [POPSpringAnimation animation];
  XCTAssertNil(anim.fromValue);
  XCTAssertNil(anim.toValue);
  XCTAssertNil(anim.velocity);

  id pointValue = [NSValue valueWithCGPoint:CGPointMake(1, 2)];
  anim.fromValue = pointValue;
  anim.toValue = pointValue;
  anim.velocity = pointValue;

  XCTAssertEqualObjects(anim.fromValue, pointValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim.toValue, pointValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim.velocity, pointValue, @"property value read should equal write");

  POPSpringAnimation *anim2 = [POPSpringAnimation animation];

  id rectValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 20, 20)];
  anim2.fromValue = rectValue;
  anim2.toValue = rectValue;
  anim2.velocity = rectValue;
  
  XCTAssertEqualObjects(anim2.fromValue, rectValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim2.toValue, rectValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim2.velocity, rectValue, @"property value read should equal write");

#if TARGET_OS_IPHONE

  POPSpringAnimation *anim3 = [POPSpringAnimation animation];

  id edgeInsetsValue = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(20, 40, 20, 40)];
  anim3.fromValue = edgeInsetsValue;
  anim3.toValue = edgeInsetsValue;
  anim3.velocity = edgeInsetsValue;

  XCTAssertEqualObjects(anim3.fromValue, edgeInsetsValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim3.toValue, edgeInsetsValue, @"property value read should equal write");
  XCTAssertEqualObjects(anim3.velocity, edgeInsetsValue, @"property value read should equal write");

#endif

  POPSpringAnimation *anim4 = [POPSpringAnimation animation];
  id transformValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
  XCTAssertThrows(anim4.fromValue = transformValue, @"should not be able to set %@", transformValue);
}

- (void)testTracer
{
  POPAnimatable *circle = [POPAnimatable new];
  POPSpringAnimation *anim = [POPSpringAnimation animation];
  POPAnimationTracer *tracer = anim.tracer;
  XCTAssertNotNil(tracer, @"missing tracer");
  [tracer start];

  NSNumber *animFromValue = @0.0;
  NSNumber *animToValue = @1.0;
  NSNumber *animVelocity = @0.1;
  float animBounciness = 4.1;
  float animSpeed = 13.0;
  float animFriction = 123.;
  float animMass = 0.9;
  float animTension = 401.;

  anim.property = self.radiusProperty;
  anim.fromValue = animFromValue;
  anim.toValue = animToValue;
  anim.velocity = animVelocity;
  anim.dynamicsFriction = animFriction;
  anim.dynamicsMass = animMass;
  anim.dynamicsTension = animTension;
  anim.springBounciness = animBounciness;
  anim.springSpeed = animSpeed;

  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 5, 0.01);
  [tracer stop];

  NSArray *allEvents = tracer.allEvents;
  NSArray *fromEvents = [tracer eventsWithType:kPOPAnimationEventFromValueUpdate];
  NSArray *toEvents = [tracer eventsWithType:kPOPAnimationEventToValueUpdate];
  NSArray *velocityEvents = [tracer eventsWithType:kPOPAnimationEventVelocityUpdate];
  NSArray *bouncinessEvents = [tracer eventsWithType:kPOPAnimationEventBouncinessUpdate];
  NSArray *speedEvents = [tracer eventsWithType:kPOPAnimationEventSpeedUpdate];
  NSArray *frictionEvents = [tracer eventsWithType:kPOPAnimationEventFrictionUpdate];
  NSArray *massEvents = [tracer eventsWithType:kPOPAnimationEventMassUpdate];
  NSArray *tensionEvents = [tracer eventsWithType:kPOPAnimationEventTensionUpdate];
  NSArray *startEvents = [tracer eventsWithType:kPOPAnimationEventDidStart];
  NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
  NSArray *didReachEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];

  // all events
  XCTAssertTrue(0 != allEvents.count, @"unexpected allEvents count %@", allEvents);

  // from events
  XCTAssertTrue(1 == fromEvents.count, @"unexpected fromEvents count %@", fromEvents);
  id eventFromValue = [(POPAnimationValueEvent *)fromEvents.lastObject value];
  XCTAssertEqualObjects(animFromValue, eventFromValue, @"unexpected eventFromValue; expected:%@ actual:%@", animFromValue, eventFromValue);

  // to events
  XCTAssertTrue(1 == toEvents.count, @"unexpected toEvents count %@", toEvents);
  id eventToValue = [(POPAnimationValueEvent *)toEvents.lastObject value];
  XCTAssertEqualObjects(animToValue, eventToValue, @"unexpected eventToValue; expected:%@ actual:%@", animToValue, eventToValue);

  // velocity events
  XCTAssertTrue(1 == velocityEvents.count, @"unexpected velocityEvents count %@", velocityEvents);
  id eventVelocity = [(POPAnimationValueEvent *)velocityEvents.lastObject value];
  XCTAssertEqualObjects(animVelocity, eventVelocity, @"unexpected eventVelocity; expected:%@ actual:%@", animVelocity, eventVelocity);

  // bounciness events
  XCTAssertTrue(1 == bouncinessEvents.count, @"unexpected bouncinessEvents count %@", bouncinessEvents);
  id eventBounciness = [(POPAnimationValueEvent *)bouncinessEvents.lastObject value];
  XCTAssertEqualObjects(@(animBounciness), eventBounciness, @"unexpected bounciness; expected:%@ actual:%@", @(animBounciness), eventBounciness);

  // speed events
  XCTAssertTrue(1 == speedEvents.count, @"unexpected speedEvents count %@", speedEvents);
  id eventSpeed = [(POPAnimationValueEvent *)speedEvents.lastObject value];
  XCTAssertEqualObjects(@(animSpeed), eventSpeed, @"unexpected speed; expected:%@ actual:%@", @(animSpeed), eventSpeed);

  // friction events
  XCTAssertTrue(1 == frictionEvents.count, @"unexpected frictionEvents count %@", frictionEvents);
  id eventFriction = [(POPAnimationValueEvent *)frictionEvents.lastObject value];
  XCTAssertEqualObjects(@(animFriction), eventFriction, @"unexpected friction; expected:%@ actual:%@", @(animFriction), eventFriction);

  // mass events
  XCTAssertTrue(1 == massEvents.count, @"unexpected massEvents count %@", massEvents);
  id eventMass = [(POPAnimationValueEvent *)massEvents.lastObject value];
  XCTAssertEqualObjects(@(animMass), eventMass, @"unexpected mass; expected:%@ actual:%@", @(animMass), eventMass);

  // tension events
  XCTAssertTrue(1 == tensionEvents.count, @"unexpected tensionEvents count %@", tensionEvents);
  id eventTension = [(POPAnimationValueEvent *)tensionEvents.lastObject value];
  XCTAssertEqualObjects(@(animTension), eventTension, @"unexpected tension; expected:%@ actual:%@", @(animTension), eventTension);

  // start & stop event
  XCTAssertTrue(1 == startEvents.count, @"unexpected startEvents count %@", startEvents);
  XCTAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);

  // start before stop
  NSUInteger startIdx = [allEvents indexOfObjectIdenticalTo:startEvents.firstObject];
  NSUInteger stopIdx = [allEvents indexOfObjectIdenticalTo:stopEvents.firstObject];
  XCTAssertTrue(startIdx < stopIdx, @"unexpected start/stop ordering startIdx:%lu stopIdx:%lu", (unsigned long)startIdx, (unsigned long)stopIdx);

  // did reach event
  XCTAssertTrue(1 == didReachEvents.count, @"unexpected didReachEvents %@", didReachEvents);

  // did reach after start before stop
  NSUInteger didReachIdx = [allEvents indexOfObjectIdenticalTo:didReachEvents.firstObject];
  XCTAssertTrue(didReachIdx > startIdx, @"unexpected didReach/start ordering didReachIdx:%lu startIdx:%lu", (unsigned long)didReachIdx, (unsigned long)startIdx);
  XCTAssertTrue(didReachIdx < stopIdx, @"unexpected didReach/stop ordering didReachIdx:%lu stopIdx:%lu", (unsigned long)didReachIdx, (unsigned long)stopIdx);

  // write events
  XCTAssertTrue(0 != writeEvents.count, @"unexpected writeEvents count %@", writeEvents);
  id firstWriteValue = [(POPAnimationValueEvent *)writeEvents.firstObject value];
  XCTAssertTrue(NSOrderedSame == [anim.fromValue compare:firstWriteValue], @"unexpected firstWriteValue; fromValue:%@ actual:%@", anim.fromValue, firstWriteValue);
  id lastWriteValue = [(POPAnimationValueEvent *)writeEvents.lastObject value];
  XCTAssertEqualObjects(lastWriteValue, anim.toValue, @"unexpected lastWriteValue; expected:%@ actual:%@", anim.toValue, lastWriteValue);
}

- (void)testAnimationContinuation
{
  POPAnimatable *circle = [POPAnimatable new];
  POPSpringAnimation *anim = [POPSpringAnimation animation];
  anim.property = self.radiusProperty;
  anim.fromValue = @0.0;
  anim.toValue = @1.0;
  anim.velocity = @10.0;
  anim.springBounciness = 4;

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  [circle pop_addAnimation:anim forKey:@"key"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 0.25, 0.05);

  NSArray *didReachToEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];
  NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];

  // assert did reach but not stop
  XCTAssertTrue(1 == didReachToEvents.count, @"unexpected didReachToEvents count %@", didReachToEvents);
  XCTAssertTrue(0 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);

  // update to value continuing animation
  anim.toValue = @0.0;
  POPAnimatorRenderDuration(self.animator, self.beginTime, 2.0, 0.1);
  [tracer stop];

  // two did reach to events
  didReachToEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];
  XCTAssertTrue(2 == didReachToEvents.count, @"unexpected didReachToEvents count %@", didReachToEvents);

  // first event value > animation to value
  id firstDidReachValue = [(POPAnimationValueEvent *)didReachToEvents.firstObject value];
  XCTAssertTrue(NSOrderedAscending == [anim.toValue compare:firstDidReachValue], @"unexpected firstDidReachValue; toValue:%@ actual:%@", anim.toValue, firstDidReachValue);

  // second event value < animation to value
  id lastDidReachValue = [(POPAnimationValueEvent *)didReachToEvents.lastObject value];
  XCTAssertTrue(NSOrderedDescending == [anim.toValue compare:lastDidReachValue], @"unexpected lastDidReachValue; toValue:%@ actual:%@", anim.toValue, lastDidReachValue);

  // did stop event
  stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
  XCTAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);
  XCTAssertEqualObjects([(POPAnimationValueEvent *)stopEvents.lastObject value], @YES, @"unexpected stop event: %@", stopEvents.lastObject);
}

- (void)testRoundingFactor
{
  POPAnimatable *circle = [POPAnimatable new];
  
  {
    // non retina, additive & non-additive
    BOOL additive = NO;
    
  LStart:
    POPBasicAnimation *anim = [POPBasicAnimation animation];
    anim.property = self.radiusProperty;
    anim.fromValue = @0.0;
    anim.toValue = @1.0;
    anim.roundingFactor = 1.0;
    anim.additive = additive;

    POPAnimationTracer *tracer = anim.tracer;
    [tracer start];

    [circle pop_addAnimation:anim forKey:@"key"];
    POPAnimatorRenderDuration(self.animator, self.beginTime, 0.25, 0.05);

    NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
    BOOL containValue = POPAnimationEventsContainValue(writeEvents, @0.5);
    XCTAssertFalse(containValue, @"unexpected write value %@", writeEvents);

    if (!additive) {
      additive = YES;
      goto LStart;
    }
  }

  {
    // retina, additive & non-additive
    BOOL additive = NO;
    
  LStartRetina:
    POPBasicAnimation *anim = [POPBasicAnimation animation];
    anim.property = self.radiusProperty;
    anim.fromValue = @0.0;
    anim.toValue = @1.0;
    anim.roundingFactor = 0.5;

    POPAnimationTracer *tracer = anim.tracer;
    [tracer start];

    [circle pop_addAnimation:anim forKey:@"key"];
    POPAnimatorRenderDuration(self.animator, self.beginTime, 0.25, 0.05);

    NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
    BOOL containValue = POPAnimationEventsContainValue(writeEvents, @0.5);
    XCTAssertTrue(containValue, @"unexpected write value %@", writeEvents);

    if (!additive) {
      additive = YES;
      goto LStartRetina;
    }
  }
}

- (void)testAdditiveAnimation
{
  const CGFloat baseValue = 1.;
  const CGFloat fromValue = 1.;
  const CGFloat toValue = 2.;
  
  POPAnimatable *circle = [POPAnimatable new];
  circle.radius = baseValue;
  
  POPBasicAnimation *anim;
  anim = [POPBasicAnimation animation];
  anim.property = self.radiusProperty;
  anim.fromValue = @(fromValue);
  anim.toValue = @(toValue);
  anim.additive = YES;
  
  [circle startRecording];
  [circle pop_addAnimation:anim forKey:@"key1"];
  
  POPAnimatorRenderDuration(self.animator, self.beginTime, 0.5, 0.05);

  NSArray *writeEvents = [circle recordedValuesForKey:@"radius"];
  CGFloat firstValue = [[writeEvents firstObject] floatValue];
  CGFloat lastValue = [[writeEvents lastObject] floatValue];
  
  XCTAssertTrue(firstValue >= baseValue + fromValue, @"write value expected:%f actual:%f", baseValue + fromValue, firstValue);
  XCTAssertTrue(lastValue == baseValue + toValue, @"write value expected:%f actual:%f", baseValue + toValue, lastValue);
}

- (void)testNilKey
{
  POPBasicAnimation *anim = FBTestLinearPositionAnimation(self.beginTime);
  
  // avoid fractional values; simplify verification
  anim.roundingFactor = 1.0;
  
  id layer = [OCMockObject niceMockForClass:[CALayer class]];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.25).cg_point()];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.5).cg_point()];
  [[layer expect] setPosition:FBTestInterpolateLinear(Vector2r([anim.fromValue CGPointValue]), Vector2r([anim.toValue CGPointValue]), 0.75).cg_point()];
  [[layer expect] setPosition:[anim.toValue CGPointValue]];
  
  // verify nil key can be added, same as CA
  [layer pop_addAnimation:anim forKey:nil];
  
  // verify attempting to remove nil key is a noop, same as CA
  XCTAssertNoThrow([layer pop_removeAnimationForKey:nil], @"unexpected exception");

  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 0.25);
  [layer verify];
}

- (void)testIntegerAnimation
{
  const int toValue = 1;
  NSNumber *boxedToValue = @1.0;

  POPBasicAnimation *anim;

  // literal
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // integer
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // short
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned short
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // int
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned int
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // long
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned long
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  XCTAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  XCTAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  anim.fromValue = @0;
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:nil];

  POPAnimatorRenderDuration(self.animator, self.beginTime + 0.1, 1, 0.1);

  // verify writes happened
  NSArray *writeEvents = tracer.writeEvents;
  XCTAssertTrue(writeEvents.count == 5, @"unexpected events:%@", writeEvents);

  // verify initial value
  POPAnimationValueEvent *firstWriteEvent = writeEvents.firstObject;
  XCTAssertTrue([firstWriteEvent.value isEqual:anim.fromValue], @"expected equality; value1:%@ value%@", firstWriteEvent.value, anim.fromValue);

  // verify final value
  XCTAssertEqualObjects([layer valueForKey:@"opacity"], anim.toValue, @"expected equality; value1:%@ value2:%@", [layer valueForKey:@"opacity"], anim.toValue);
}

- (void)testPlatformColorSupport
{
  POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBackgroundColor];

#if TARGET_OS_IPHONE
  XCTAssertNoThrow(anim.fromValue = [UIColor whiteColor], @"unexpected exception");
  XCTAssertNoThrow(anim.toValue = [UIColor redColor], @"unexpected exception");
#else
  XCTAssertNoThrow(anim.fromValue = [NSColor whiteColor], @"unexpected exception");
  XCTAssertNoThrow(anim.toValue = [NSColor redColor], @"unexpected exception");
#endif
  
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];
  
  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:@"color"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 0.1);

  // expect some interpolation
  NSArray *writeEvents = tracer.writeEvents;
  XCTAssertTrue(writeEvents.count > 1, @"unexpected write events %@", writeEvents);

  // get layer color components
  CGFloat layerValues[4];
  POPCGColorGetRGBAComponents(layer.backgroundColor, layerValues);

  // get to color components
  CGFloat toValues[4];
  POPCGColorGetRGBAComponents((__bridge CGColorRef)anim.toValue, toValues);

  // assert equality
  XCTAssertTrue(layerValues[0] == toValues[0] && layerValues[1] == toValues[1] && layerValues[2] == toValues[2] && layerValues[3] == toValues[3], @"unexpected last color: [r:%f g:%f b:%f a:%f]", layerValues[0], layerValues[1], layerValues[2], layerValues[3]);
}

@end
