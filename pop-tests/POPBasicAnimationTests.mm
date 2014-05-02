//
//  POPBasicAnimationTests.m
//  pop
//
//  Created by Kimon Tsinteris on 5/2/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

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
  anim.fromValue = [UIColor whiteColor];
  anim.toValue = [UIColor redColor];

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
