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
#import <POP/POPAnimationPrivate.h>
#import <POP/POPAnimatorPrivate.h>

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
  STAssertThrows([[POPAnimation alloc] init], @"should not be able to instiate abstract class");
  STAssertThrows([[POPPropertyAnimation alloc] init], @"should not be able to instiate abstract class");
}

- (void)testWithPropertyNamedConstruction
{
  POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
  POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];
  STAssertTrue(anim.property == prop, @"expected:%@ actual:%@", prop, anim.property);
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
  STAssertTrue(1 == keys.count, nil);
  STAssertTrue([@"hello" isEqualToString:keys.lastObject], nil);

  [layer1 pop_removeAnimationForKey:@"hello"];
  STAssertTrue(0 == [layer1 pop_animationKeys].count, nil);

  [layer1 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"hello"];
  [layer1 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"world"];
  [layer2 pop_addAnimation:FBTestLinearPositionAnimation(self.beginTime) forKey:@"hello"];

  STAssertTrue(2 == [layer1 pop_animationKeys].count, nil);
  STAssertTrue(1 == [layer2 pop_animationKeys].count, nil);

  [layer1 pop_removeAllAnimations];
  STAssertTrue(0 == [layer1 pop_animationKeys].count, nil);
  STAssertTrue(1 == [layer2 pop_animationKeys].count, nil);
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
  STAssertTrue(1 == didStartEvents.count, @"unexpected start events %@", didStartEvents);
  STAssertTrue(1 == didStopEvents.count, @"unexpected stop events %@", didStopEvents);
}

- (void)testAddedKeys
{
  POPAnimation *anim = FBTestLinearPositionAnimation();
  anim.sampleKey = @"value";
  STAssertEqualObjects(anim.sampleKey, @"value", @"property value read should equal write");
}

- (void)testValueTypeResolution
{
  POPSpringAnimation *anim = [POPSpringAnimation animation];
  STAssertNil(anim.fromValue, nil);
  STAssertNil(anim.toValue, nil);
  STAssertNil(anim.velocity, nil);

  id pointValue = [NSValue valueWithCGPoint:CGPointMake(1, 2)];
  anim.fromValue = pointValue;
  anim.toValue = pointValue;
  anim.velocity = pointValue;

  STAssertEqualObjects(anim.fromValue, pointValue, @"property value read should equal write");
  STAssertEqualObjects(anim.toValue, pointValue, @"property value read should equal write");
  STAssertEqualObjects(anim.velocity, pointValue, @"property value read should equal write");

  POPSpringAnimation *anim2 = [POPSpringAnimation animation];

  id rectValue = [NSValue valueWithCGRect:CGRectMake(0, 0, 20, 20)];
  anim2.fromValue = rectValue;
  anim2.toValue = rectValue;
  anim2.velocity = rectValue;
  
  STAssertEqualObjects(anim2.fromValue, rectValue, @"property value read should equal write");
  STAssertEqualObjects(anim2.toValue, rectValue, @"property value read should equal write");
  STAssertEqualObjects(anim2.velocity, rectValue, @"property value read should equal write");

  POPSpringAnimation *anim3 = [POPSpringAnimation animation];
  id transformValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
  STAssertThrows(anim3.fromValue = transformValue, @"should not be able to set %@", transformValue);
}

- (void)testTracer
{
  POPAnimatable *circle = [POPAnimatable new];
  POPSpringAnimation *anim = [POPSpringAnimation animation];
  POPAnimationTracer *tracer = anim.tracer;
  STAssertNotNil(tracer, @"missing tracer");
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
  STAssertTrue(0 != allEvents.count, @"unexpected allEvents count %@", allEvents);

  // from events
  STAssertTrue(1 == fromEvents.count, @"unexpected fromEvents count %@", fromEvents);
  id eventFromValue = [(POPAnimationValueEvent *)fromEvents.lastObject value];
  STAssertEqualObjects(animFromValue, eventFromValue, @"unexpected eventFromValue; expected:%@ actual:%@", animFromValue, eventFromValue);

  // to events
  STAssertTrue(1 == toEvents.count, @"unexpected toEvents count %@", toEvents);
  id eventToValue = [(POPAnimationValueEvent *)toEvents.lastObject value];
  STAssertEqualObjects(animToValue, eventToValue, @"unexpected eventToValue; expected:%@ actual:%@", animToValue, eventToValue);

  // velocity events
  STAssertTrue(1 == velocityEvents.count, @"unexpected velocityEvents count %@", velocityEvents);
  id eventVelocity = [(POPAnimationValueEvent *)velocityEvents.lastObject value];
  STAssertEqualObjects(animVelocity, eventVelocity, @"unexpected eventVelocity; expected:%@ actual:%@", animVelocity, eventVelocity);

  // bounciness events
  STAssertTrue(1 == bouncinessEvents.count, @"unexpected bouncinessEvents count %@", bouncinessEvents);
  id eventBounciness = [(POPAnimationValueEvent *)bouncinessEvents.lastObject value];
  STAssertEqualObjects(@(animBounciness), eventBounciness, @"unexpected bounciness; expected:%@ actual:%@", @(animBounciness), eventBounciness);

  // speed events
  STAssertTrue(1 == speedEvents.count, @"unexpected speedEvents count %@", speedEvents);
  id eventSpeed = [(POPAnimationValueEvent *)speedEvents.lastObject value];
  STAssertEqualObjects(@(animSpeed), eventSpeed, @"unexpected speed; expected:%@ actual:%@", @(animSpeed), eventSpeed);

  // friction events
  STAssertTrue(1 == frictionEvents.count, @"unexpected frictionEvents count %@", frictionEvents);
  id eventFriction = [(POPAnimationValueEvent *)frictionEvents.lastObject value];
  STAssertEqualObjects(@(animFriction), eventFriction, @"unexpected friction; expected:%@ actual:%@", @(animFriction), eventFriction);

  // mass events
  STAssertTrue(1 == massEvents.count, @"unexpected massEvents count %@", massEvents);
  id eventMass = [(POPAnimationValueEvent *)massEvents.lastObject value];
  STAssertEqualObjects(@(animMass), eventMass, @"unexpected mass; expected:%@ actual:%@", @(animMass), eventMass);

  // tension events
  STAssertTrue(1 == tensionEvents.count, @"unexpected tensionEvents count %@", tensionEvents);
  id eventTension = [(POPAnimationValueEvent *)tensionEvents.lastObject value];
  STAssertEqualObjects(@(animTension), eventTension, @"unexpected tension; expected:%@ actual:%@", @(animTension), eventTension);

  // start & stop event
  STAssertTrue(1 == startEvents.count, @"unexpected startEvents count %@", startEvents);
  STAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);

  // start before stop
  NSUInteger startIdx = [allEvents indexOfObjectIdenticalTo:startEvents.firstObject];
  NSUInteger stopIdx = [allEvents indexOfObjectIdenticalTo:stopEvents.firstObject];
  STAssertTrue(startIdx < stopIdx, @"unexpected start/stop ordering startIdx:%d stopIdx:%d", startIdx, stopIdx);

  // did reach event
  STAssertTrue(1 == didReachEvents.count, @"unexpected didReachEvents %@", didReachEvents);

  // did reach after start before stop
  NSUInteger didReachIdx = [allEvents indexOfObjectIdenticalTo:didReachEvents.firstObject];
  STAssertTrue(didReachIdx > startIdx, @"unexpected didReach/start ordering didReachIdx:%d startIdx:%d", didReachIdx, startIdx);
  STAssertTrue(didReachIdx < stopIdx, @"unexpected didReach/stop ordering didReachIdx:%d stopIdx:%d", didReachIdx, stopIdx);

  // write events
  STAssertTrue(0 != writeEvents.count, @"unexpected writeEvents count %@", writeEvents);
  id firstWriteValue = [(POPAnimationValueEvent *)writeEvents.firstObject value];
  STAssertTrue(NSOrderedSame == [anim.fromValue compare:firstWriteValue], @"unexpected firstWriteValue; fromValue:%@ actual:%@", anim.fromValue, firstWriteValue);
  id lastWriteValue = [(POPAnimationValueEvent *)writeEvents.lastObject value];
  STAssertEqualObjects(lastWriteValue, anim.toValue, @"unexpected lastWriteValue; expected:%@ actual:%@", anim.toValue, lastWriteValue);
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
  STAssertTrue(1 == didReachToEvents.count, @"unexpected didReachToEvents count %@", didReachToEvents);
  STAssertTrue(0 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);

  // update to value continuing animation
  anim.toValue = @0.0;
  POPAnimatorRenderDuration(self.animator, self.beginTime, 2.0, 0.1);
  [tracer stop];

  // two did reach to events
  didReachToEvents = [tracer eventsWithType:kPOPAnimationEventDidReachToValue];
  STAssertTrue(2 == didReachToEvents.count, @"unexpected didReachToEvents count %@", didReachToEvents);

  // first event value > animation to value
  id firstDidReachValue = [(POPAnimationValueEvent *)didReachToEvents.firstObject value];
  STAssertTrue(NSOrderedAscending == [anim.toValue compare:firstDidReachValue], @"unexpected firstDidReachValue; toValue:%@ actual:%@", anim.toValue, firstDidReachValue);

  // second event value < animation to value
  id lastDidReachValue = [(POPAnimationValueEvent *)didReachToEvents.lastObject value];
  STAssertTrue(NSOrderedDescending == [anim.toValue compare:lastDidReachValue], @"unexpected lastDidReachValue; toValue:%@ actual:%@", anim.toValue, lastDidReachValue);

  // did stop event
  stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
  STAssertTrue(1 == stopEvents.count, @"unexpected stopEvents count %@", stopEvents);
  STAssertEqualObjects([(POPAnimationValueEvent *)stopEvents.lastObject value], @YES, @"unexpected stop event: %@", stopEvents.lastObject);
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
    STAssertFalse(containValue, @"unexpected write value %@", writeEvents);

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
    STAssertTrue(containValue, @"unexpected write value %@", writeEvents);

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
  
  STAssertTrue(firstValue >= baseValue + fromValue, @"write value expected:%f actual:%f", baseValue + fromValue, firstValue);
  STAssertTrue(lastValue == baseValue + toValue, @"write value expected:%f actual:%f", baseValue + toValue, lastValue);
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
  STAssertNoThrow([layer pop_removeAnimationForKey:nil], @"unexpected exception");

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
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // integer
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // short
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned short
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // int
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned int
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // long
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  // unsigned long
  anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
  STAssertNoThrow(anim.toValue = @(toValue), @"unexpected exception");
  STAssertEqualObjects(anim.toValue, boxedToValue, @"expected equality; value1:%@ value2:%@", anim.toValue, boxedToValue);

  anim.fromValue = @0;
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:nil];

  POPAnimatorRenderDuration(self.animator, self.beginTime + 0.1, 1, 0.1);

  // verify writes happened
  NSArray *writeEvents = tracer.writeEvents;
  STAssertTrue(writeEvents.count == 5, @"unexpected events:%@", writeEvents);

  // verify initial value
  POPAnimationValueEvent *firstWriteEvent = writeEvents.firstObject;
  STAssertTrue([firstWriteEvent.value isEqual:anim.fromValue], @"expected equality; value1:%@ value%@", firstWriteEvent.value, anim.fromValue);

  // verify final value
  STAssertEqualObjects([layer valueForKey:@"opacity"], anim.toValue, @"expected equality; value1:%@ value2:%@", [layer valueForKey:@"opacity"], anim.toValue);
}

- (void)testPlatformColorSupport
{
  POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBackgroundColor];

#if TARGET_OS_IPHONE
  STAssertNoThrow(anim.fromValue = [UIColor whiteColor], @"unexpected exception");
  STAssertNoThrow(anim.toValue = [UIColor redColor], @"unexpected exception");
#else
  STAssertNoThrow(anim.fromValue = [NSColor whiteColor], @"unexpected exception");
  STAssertNoThrow(anim.toValue = [NSColor redColor], @"unexpected exception");
#endif
  
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];
  
  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:@"color"];
  POPAnimatorRenderDuration(self.animator, self.beginTime, 1, 0.1);

  // expect some interpolation
  NSArray *writeEvents = tracer.writeEvents;
  STAssertTrue(writeEvents.count > 1, @"unexpected write events %@", writeEvents);

  // get layer color components
  CGFloat layerValues[4];
  POPCGColorGetRGBAComponents(layer.backgroundColor, layerValues);

  // get to color components
  CGFloat toValues[4];
  POPCGColorGetRGBAComponents((__bridge CGColorRef)anim.toValue, toValues);

  // assert equality
  STAssertTrue(layerValues[0] == toValues[0] && layerValues[1] == toValues[1] && layerValues[2] == toValues[2] && layerValues[3] == toValues[3], @"unexpected last color: [r:%f g:%f b:%f a:%f]", layerValues[0], layerValues[1], layerValues[2], layerValues[3]);
}

@end
