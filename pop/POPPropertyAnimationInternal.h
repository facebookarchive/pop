/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationInternal.h"
#import "POPPropertyAnimation.h"

static void clampValue(CGFloat &value, CGFloat fromValue, CGFloat toValue, NSUInteger clamp)
{
  BOOL increasing = (toValue > fromValue);

  // Clamp start of animation.
  if ((kPOPAnimationClampStart & clamp) &&
      ((increasing && (value < fromValue)) || (!increasing && (value > fromValue)))) {
    value = fromValue;
  }

  // Clamp end of animation.
  if ((kPOPAnimationClampEnd & clamp) &&
      ((increasing && (value > toValue)) || (!increasing && (value < toValue)))) {
    value = toValue;
  }
}

struct _POPPropertyAnimationState : _POPAnimationState
{
  POPAnimatableProperty *property;
  POPValueType valueType;
  NSUInteger valueCount;
  VectorRef fromVec;
  VectorRef toVec;
  VectorRef currentVec;
  VectorRef previousVec;
  VectorRef previous2Vec;
  VectorRef velocityVec;
  VectorRef distanceVec;
  CGFloat roundingFactor;
  NSUInteger clampMode;
  NSArray *progressMarkers;
  POPProgressMarker *progressMarkerState;
  NSUInteger progressMarkerCount;
  NSUInteger nextProgressMarkerIdx;
  CGFloat dynamicsThreshold;

  _POPPropertyAnimationState(id __unsafe_unretained anim) : _POPAnimationState(anim),
  property(nil),
  valueType((POPValueType)0),
  valueCount(0),
  fromVec(nullptr),
  toVec(nullptr),
  currentVec(nullptr),
  previousVec(nullptr),
  previous2Vec(nullptr),
  velocityVec(nullptr),
  distanceVec(nullptr),
  roundingFactor(0),
  clampMode(0),
  progressMarkers(nil),
  progressMarkerState(nil),
  progressMarkerCount(0),
  nextProgressMarkerIdx(0),
  dynamicsThreshold(0)
  {
    type = kPOPAnimationBasic;
  }

  ~_POPPropertyAnimationState()
  {
    if (progressMarkerState) {
      free(progressMarkerState);
      progressMarkerState = NULL;
    }
  }

  bool canProgress() {
    return hasValue();
  }

  bool shouldRound() {
    return 0 != roundingFactor;
  }

  bool hasValue() {
    return 0 != valueCount;
  }

  bool isDone() {
    // inherit done
    if (_POPAnimationState::isDone()) {
      return true;
    }

    // consider an animation with no values done
    if (!hasValue() && !isCustom()) {
      return true;
    }

    return false;
  }

  // returns a copy of the currentVec, rounding if needed
  VectorRef currentValue() {
    VectorRef vec = VectorRef(Vector::new_vector(currentVec.get()));
    if (shouldRound()) {
      vec->subRound(1 / roundingFactor);
    }
      return vec;
  }

  void resetProgressMarkerState()
  {
    for (NSUInteger idx = 0; idx < progressMarkerCount; idx++)
      progressMarkerState[idx].reached = false;

    nextProgressMarkerIdx = 0;
  }

  void updatedProgressMarkers()
  {
    if (progressMarkerState) {
      free(progressMarkerState);
      progressMarkerState = NULL;
    }

    progressMarkerCount = progressMarkers.count;

    if (0 != progressMarkerCount) {
      progressMarkerState = (POPProgressMarker *)malloc(progressMarkerCount * sizeof(POPProgressMarker));
      [progressMarkers enumerateObjectsUsingBlock:^(NSNumber *progressMarker, NSUInteger idx, BOOL *stop) {
        progressMarkerState[idx].reached = false;
        progressMarkerState[idx].progress = [progressMarker floatValue];
      }];
    }

    nextProgressMarkerIdx = 0;
  }

  virtual void updatedDynamicsThreshold()
  {
    dynamicsThreshold = property.threshold;
  }

  bool advanceProgress(CGFloat p)
  {
    bool advanced = progress != p;
    if (advanced) {
      progress = p;
      NSUInteger count = valueCount;
      VectorRef outVec(Vector::new_vector(count, NULL));

      if (1.0 == progress) {
        if (outVec && toVec) {
          *outVec = *toVec;
        }
      } else {
        POPInterpolateVector(count, vec_data(outVec), vec_data(fromVec), vec_data(toVec), progress);
      }

      currentVec = outVec;
      clampCurrentValue();
      delegateProgress();
    }
    return advanced;
  }

  void computeProgress() {
    if (!canProgress()) {
      return;
    }

    static ComputeProgressFunctor<Vector4r> func;
    Vector4r v = vector4(currentVec);
    Vector4r f = vector4(fromVec);
    Vector4r t = vector4(toVec);
    progress = func(v, f, t);
  }

  void delegateProgress() {
    if (!canProgress()) {
      return;
    }

    if (delegateDidProgress && progressMarkerState) {

      while (nextProgressMarkerIdx < progressMarkerCount) {
        if (progress < progressMarkerState[nextProgressMarkerIdx].progress)
          break;

        if (!progressMarkerState[nextProgressMarkerIdx].reached) {
          ActionEnabler enabler;
          [delegate pop_animation:self didReachProgress:progressMarkerState[nextProgressMarkerIdx].progress];
          progressMarkerState[nextProgressMarkerIdx].reached = true;
        }

        nextProgressMarkerIdx++;
      }
    }

    if (!didReachToValue) {
      bool didReachToValue = false;
      if (0 == valueCount) {
        didReachToValue = true;
      } else {
        Vector4r distance = toVec->vector4r();
        distance -= currentVec->vector4r();

        if (0 == distance.squaredNorm()) {
          didReachToValue = true;
        } else {
          // components
          if (distanceVec) {
            didReachToValue = true;
            const CGFloat *distanceValues = distanceVec->data();
            for (NSUInteger idx = 0; idx < valueCount; idx++) {
              didReachToValue &= (signbit(distance[idx]) != signbit(distanceValues[idx]));
            }
          }
        }
      }

      if (didReachToValue) {
        handleDidReachToValue();
      }
    }
  }

  void handleDidReachToValue() {
    didReachToValue = true;

    if (delegateDidReachToValue) {
      ActionEnabler enabler;
      [delegate pop_animationDidReachToValue:self];
    }

    if (tracing) {
      [tracer didReachToValue:POPBox(currentValue(), valueType, true)];
    }
  }

  void readObjectValue(VectorRef *ptrVec, id obj)
  {
    // use current object value as from value
    pop_animatable_read_block read = property.readBlock;
    if (NULL != read) {

      Vector4r vec = read_values(read, obj, valueCount);
      *ptrVec = VectorRef(Vector::new_vector(valueCount, vec));

      if (tracing) {
        [tracer readPropertyValue:POPBox(*ptrVec, valueType, true)];
      }
    }
  }

  virtual void willRun(bool started, id obj) {
    // ensure from value initialized
    if (NULL == fromVec) {
      readObjectValue(&fromVec, obj);
    }

    // ensure to value initialized
    if (NULL == toVec) {
      // compute decay to value
      if (kPOPAnimationDecay == type) {
        [self toValue];
      } else {
        // read to value
        readObjectValue(&toVec, obj);
      }
    }

    // handle one time value initialization on start
    if (started) {

      // initialize current vec
      if (!currentVec) {
        currentVec = VectorRef(Vector::new_vector(valueCount, NULL));

        // initialize current value with from value
        // only do this on initial creation to avoid overwriting current value
        // on paused animation continuation
        if (currentVec && fromVec) {
          *currentVec = *fromVec;
        }
      }

      // ensure velocity values
      if (!velocityVec) {
        velocityVec = VectorRef(Vector::new_vector(valueCount, NULL));
      }
    }

    // ensure distance value initialized
    // depends on current value set on one time start
    if (NULL == distanceVec) {

      // not yet started animations may not have current value
      VectorRef fromVec2 = NULL != currentVec ? currentVec : fromVec;

      if (fromVec2 && toVec) {
        Vector4r distance = toVec->vector4r();
        distance -= fromVec2->vector4r();

        if (0 != distance.squaredNorm()) {
          distanceVec = VectorRef(Vector::new_vector(valueCount, distance));
        }
      }
    }
  }

  virtual void reset(bool all) {
    _POPAnimationState::reset(all);

    if (all) {
      currentVec = NULL;
      previousVec = NULL;
      previous2Vec = NULL;
    }
    progress = 0;
    resetProgressMarkerState();
    didReachToValue = false;
    distanceVec = NULL;
  }

  void clampCurrentValue(NSUInteger clamp)
  {
    if (kPOPAnimationClampNone == clamp)
      return;

    // Clamp all vector values
    CGFloat *currentValues = currentVec->data();
    const CGFloat *fromValues = fromVec->data();
    const CGFloat *toValues = toVec->data();

    for (NSUInteger idx = 0; idx < valueCount; idx++) {
      clampValue(currentValues[idx], fromValues[idx], toValues[idx], clamp);
    }
  }

  void clampCurrentValue()
  {
    clampCurrentValue(clampMode);
  }
};

typedef struct _POPPropertyAnimationState POPPropertyAnimationState;

@interface POPPropertyAnimation ()

@end

