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

#import "POPAnimationTestsExtras.h"

@interface POPAnimationMRRTests : SenTestCase
{
  POPAnimator *_animator;
  CFTimeInterval _beginTime;
}
@end

@implementation POPAnimationMRRTests

- (void)setUp
{
  [super setUp];
  _animator = [[POPAnimator sharedAnimator] retain];
  _beginTime = CACurrentMediaTime();
  _animator.beginTime = _beginTime;
}

- (void)tearDown
{
  [_animator release];
  _animator = nil;
  [super tearDown];
}

- (void)testZeroingDelegate
{
  POPBasicAnimation *anim = FBTestLinearPositionAnimation();

  @autoreleasepool {
    id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];
    anim.delegate = delegate;
    STAssertNotNil(anim.delegate, @"delegate should not be nil");
  }

  STAssertNil(anim.delegate, @"delegate should be nil");
}

- (void)testAnimationCancellationOnAnimatableDeallocation
{
  id layer = nil;
  POPBasicAnimation *anim = FBTestLinearPositionAnimation();
  id delegate = [OCMockObject niceMockForProtocol:@protocol(POPAnimationDelegate)];

  @autoreleasepool {
    layer = [OCMockObject niceMockForClass:[CALayer class]];
    anim.delegate = delegate;

    // expect position start
    [[delegate expect] pop_animationDidStart:anim];

    // run
    [layer pop_addAnimation:anim forKey:@""];
    POPAnimatorRenderTimes(_animator, _beginTime, @[@0.0]);

    // verify
    [layer verify];
    [delegate verify];

    // expect stop unfinished
    [[delegate expect] pop_animationDidStop:anim finished:NO];
    layer = nil;
  }

  // run
  POPAnimatorRenderTimes(_animator, _beginTime, @[@0.5]);

  // verify
  [delegate verify];
}

@end
