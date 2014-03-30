/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPVector.h"
@class POPAnimator;
@class POPBasicAnimation;

extern void POPAnimatorRenderTimes(POPAnimator *animator, CFTimeInterval beginTime, NSArray *times);
extern void POPAnimatorRenderDuration(POPAnimator *animator, CFAbsoluteTime beginTime, CFTimeInterval duration, CFTimeInterval step);

extern POPBasicAnimation *FBTestLinearPositionAnimation(CFTimeInterval beginTime = 0);
extern POP::Vector2r FBTestInterpolateLinear(POP::Vector2r start, POP::Vector2r end, CGFloat progress);
