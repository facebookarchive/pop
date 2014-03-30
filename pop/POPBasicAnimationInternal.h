/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPBasicAnimation.h"
#import "POPPropertyAnimationInternal.h"

// default animation duration
static CGFloat kPOPAnimationDurationDefault = 0.4;

static void interpolate(POPValueType valueType, NSUInteger count, const CGFloat *fromVec, const CGFloat *toVec, CGFloat *outVec, double p)
{
  switch (valueType) {
    case kPOPValueInteger:
    case kPOPValueFloat:
    case kPOPValuePoint:
    case kPOPValueSize:
    case kPOPValueRect:
      interpolate_vector(count, outVec, fromVec, toVec, p);
      break;
    default:
      NSCAssert(false, @"unhandled type %d", valueType);
      break;
  }
}

struct _POPBasicAnimationState : _POPPropertyAnimationState
{
  CAMediaTimingFunction *timingFunction;
  double timingControlPoints[4];
  CFTimeInterval duration;

  _POPBasicAnimationState(id __unsafe_unretained anim) : _POPPropertyAnimationState(anim),
  duration(kPOPAnimationDurationDefault),
  timingFunction(nil)
  {
    type = kPOPAnimationBasic;
    memset(timingControlPoints, 0, sizeof(timingControlPoints));
  }

  bool isDone() {
    if (_POPPropertyAnimationState::isDone()) {
      return true;
    }
    return _EQLF_(progress, 1., 1e-2);
  }

  void updatedTimingFunction()
  {
    float vec[4] = {0., 0., 0., 0.};
    [timingFunction getControlPointAtIndex:1 values:&vec[0]];
    [timingFunction getControlPointAtIndex:2 values:&vec[2]];
    for (NSUInteger idx = 0; idx < POP_ARRAY_COUNT(vec); idx++) {
      timingControlPoints[idx] = vec[idx];
    }
  }

  bool advance(CFTimeInterval time, CFTimeInterval dt, id obj) {
    // default timing function
    if (!timingFunction) {
      ((POPBasicAnimation *)self).timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    }

    // cap local time to duration
    CFTimeInterval t = MIN(time - startTime, duration) / duration;

    // solve for normalized time, aka progresss [0, 1]
    double p = timing_function_solve(timingControlPoints, t, SOLVE_EPS(duration));

    // interpolate and advance
    if (p != progress) {
      interpolate(valueType, valueCount, fromVec->data(), toVec->data(), currentVec->data(), p);
      progress = p;
      return true;
    }

    clampCurrentValue();

    return false;
  }
};

typedef struct _POPBasicAnimationState POPBasicAnimationState;
