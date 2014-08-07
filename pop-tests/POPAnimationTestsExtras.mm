/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationTestsExtras.h"

#import <pop/POP.h>
#import <pop/POPAnimatorPrivate.h>

void POPAnimatorRenderTime(POPAnimator *animator, CFTimeInterval beginTime, CFTimeInterval time)
{
  [animator renderTime:beginTime + time];
}

void POPAnimatorRenderTimes(POPAnimator *animator, CFTimeInterval beginTime, NSArray *times)
{
  for (NSNumber *time in times) {
    [animator renderTime:beginTime + time.doubleValue];
  }
}

void POPAnimatorRenderDuration(POPAnimator *animator, CFTimeInterval beginTime, CFTimeInterval duration, CFTimeInterval step)
{
  CFTimeInterval initialTime = animator.beginTime;
  animator.beginTime = beginTime;
  NSCAssert(step > 0, @"unexpected step %f", step);
  CFTimeInterval time = 0;
  while(time <= duration) {
    [animator renderTime:beginTime + time];
    time += step;
  }
  animator.beginTime = initialTime;
}

POPBasicAnimation *FBTestLinearPositionAnimation(CFTimeInterval beginTime)
{
  POPBasicAnimation *anim = [POPBasicAnimation linearAnimation];
  anim.property = [POPAnimatableProperty propertyWithName:kPOPLayerPosition];
  anim.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
  anim.toValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
  anim.duration = 1;
  anim.beginTime = beginTime;
  return anim;
}

POP::Vector2r FBTestInterpolateLinear(POP::Vector2r start, POP::Vector2r end, CGFloat progress)
{
  return start + ((end - start) * progress);
}
