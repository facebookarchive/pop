/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <SenTestingKit/SenTestingKit.h>

#import <OCMock/OCMock.h>
#import <pop/POPBasicAnimation.h>

#import "POPAnimatable.h"
#import "POPAnimationTestsExtras.h"
#import "POPBaseAnimationTests.h"

@interface POPBasicAnimationTests : POPBaseAnimationTests

@end

@implementation POPBasicAnimationTests

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
  STAssertTrue(writeEvents.count > 5, @"expected more write events %@", tracer.allEvents);

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
    STAssertTrue(writeEvents.count == 1, @"expected one write event %@", tracer.allEvents);
    NSArray *stopEvents = [tracer eventsWithType:kPOPAnimationEventDidStop];
    STAssertTrue(stopEvents.count == 1, @"expected one stop event %@", tracer.allEvents);
    
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
  STAssertTrue(UIEdgeInsetsEqualToEdgeInsets(lastEdgeInsets, toEdgeInsets), @"unexpected last edge insets value: %@", lastEvent);
}
#endif

@end
