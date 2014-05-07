/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <SenTestingKit/SenTestingKit.h>

#import <OCMock/OCMock.h>
#import <POP/POPBasicAnimation.h>

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

@end
