/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <pop/POPBasicAnimation.h>
#import <QuartzCore/QuartzCore.h>

////////////////////////////////////////////////////////////
// POPCustomEasingAnimation
@interface POPCustomEasingAnimation : POPBasicAnimation
+ (instancetype)animationWithEasingFunction:(CGFloat (^)(CGFloat t))easingFunction;

@property (nonatomic, copy) CGFloat (^easingFunction)(CGFloat t);
@end

////////////////////////////////////////////////////////////
// CAMediaTimingFunction (GoogleAnimationCurve)
@interface CAMediaTimingFunction (GoogleAnimationCurve)
+ (CAMediaTimingFunction *)swiftOut;
@end
