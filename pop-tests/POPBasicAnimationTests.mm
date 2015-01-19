/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#import <pop/POPBasicAnimation.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"

@interface POPBasicAnimationTests : POPBaseAnimationTests

@end

@implementation POPBasicAnimationTests

- (void)testGreaterThanOneControlPointC1Y
{
  POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerPositionX];
  anim.fromValue = @0;
  anim.toValue = @100;
  anim.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.15f :1.5f :0.55f :1.0f];
  anim.duration = 0.36;

  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:nil];

  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);

  // verify write count
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  XCTAssertTrue(writeEvents.count > 10, @"expected more write events %@", tracer.allEvents);
  
  // verify last written value is equal to animation to value
  id lastValue = [(POPAnimationValueEvent *)writeEvents.lastObject value];
  XCTAssertEqualObjects(lastValue, anim.toValue, @"expected more write events %@", tracer.allEvents);
  
  // verify last written value is less than previous value
  id prevLastValue = [(POPAnimationValueEvent *)writeEvents[writeEvents.count - 2] value];
  XCTAssertTrue(NSOrderedDescending == [prevLastValue compare:lastValue], @"unexpected lastValue; prevLastValue:%@ events:%@", prevLastValue, tracer.allEvents);
}

- (void)testColorInterpolation
{
  POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerBackgroundColor];

#if TARGET_OS_IPHONE
  anim.fromValue = [UIColor whiteColor];
  anim.toValue = [UIColor redColor];
#else
  anim.fromValue = [NSColor whiteColor];
  anim.toValue = [NSColor redColor];
#endif
  
  POPAnimationTracer *tracer = anim.tracer;
  [tracer start];

  CALayer *layer = [CALayer layer];
  [layer pop_addAnimation:anim forKey:nil];

  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);

  // verify write events
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  XCTAssertTrue(writeEvents.count > 5, @"expected more write events %@", tracer.allEvents);

  // assert final value
  POPAssertColorEqual((__bridge CGColorRef)anim.toValue, layer.backgroundColor);
}

- (void)testZeroDurationAnimation
{
    POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerBackgroundColor];
    anim.duration = 0.0f;
    
#if TARGET_OS_IPHONE
    anim.fromValue = [UIColor whiteColor];
    anim.toValue = [UIColor redColor];
#else
    anim.fromValue = [NSColor whiteColor];
    anim.toValue = [NSColor redColor];
#endif
    
    POPAnimationTracer *tracer = anim.tracer;
    [tracer start];
    
    CALayer *layer = [CALayer layer];
    [layer pop_addAnimation:anim forKey:nil];
    
    // run animation
    POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);
    
    // verify write events
    NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
    XCTAssertTrue(writeEvents.count == 1, @"expected one write event %@", tracer.allEvents);
    NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
    XCTAssertTrue(stopEvents.count == 1, @"expected one stop event %@", tracer.allEvents);
    
    // assert final value
    POPAssertColorEqual((__bridge CGColorRef)anim.toValue, layer.backgroundColor);
}

#if TARGET_OS_IPHONE
- (void)testEdgeInsetsSupport
{
  const UIEdgeInsets fromEdgeInsets = UIEdgeInsetsZero;
  const UIEdgeInsets toEdgeInsets = UIEdgeInsetsMake(100, 200, 200, 400);
  
  POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
  anim.fromValue = [NSValue valueWithUIEdgeInsets:fromEdgeInsets];
  anim.toValue = [NSValue valueWithUIEdgeInsets:toEdgeInsets];
  
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
  
  // expect final value to be set
  [[scrollView expect] setContentInset:toEdgeInsets];
  
  // run animation
  POPAnimatorRenderDuration(self.animator, self.beginTime, 3, 1.0/60.0);
  
  NSArray *writeEvents = [tracer eventsWithType:kPOPAnimationEventPropertyWrite];
  
  // verify delegate
  [delegate verify];
  
  // verify scroll view
  [scrollView verify];
  
  POPAnimationValueEvent *lastEvent = [writeEvents lastObject];
  UIEdgeInsets lastEdgeInsets = [lastEvent.value UIEdgeInsetsValue];
  
  // verify last insets are to insets
  XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(lastEdgeInsets, toEdgeInsets), @"unexpected last edge insets value: %@", lastEvent);
}
#endif

@end
