/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <SenTestingKit/SenTestingKit.h>

@class CALayer;
@class POPAnimator;
@class POPAnimatableProperty;

@interface POPBaseAnimationTests : SenTestCase

// two layers for test use
@property (strong, nonatomic) CALayer *layer1, *layer2;

// the animator to use for rendering
@property (strong, nonatomic) POPAnimator *animator;

// the time tests began
@property (assign, nonatomic) CFTimeInterval beginTime;

// radius animatable property
@property (strong, nonatomic) POPAnimatableProperty *radiusProperty;

@end

// max frame count required for animations to converge
extern NSUInteger kPOPAnimationConvergenceMaxFrameCount;

// counts the number of events of value within epsilon, starting from end
extern NSUInteger POPAnimationCountLastEventValues(NSArray *events, NSNumber *value, float epsilon = 0);

// returns YES if array of value events contain specified value
extern BOOL POPAnimationEventsContainValue(NSArray *events, NSNumber *value);
