/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationExtras.h"
#import "POPPropertyAnimationInternal.h"
#import "POPSpringAnimation.h"

struct _POPSpringAnimationState : _POPPropertyAnimationState
{
  SpringSolver4d *solver;
  CGFloat springSpeed;
  CGFloat springBounciness; // normalized springiness
  CGFloat dynamicsTension;  // tension
  CGFloat dynamicsFriction; // friction
  CGFloat dynamicsMass;     // mass

  _POPSpringAnimationState(id __unsafe_unretained anim) : _POPPropertyAnimationState(anim),
  solver(nullptr),
  springSpeed(12.),
  springBounciness(4.),
  dynamicsTension(0),
  dynamicsFriction(0),
  dynamicsMass(0)
  {
    type = kPOPAnimationSpring;
  }

  bool hasConverged()
  {
    NSUInteger count = valueCount;
    if (shouldRound()) {
      return vec_equal(previous2Vec, previousVec) && vec_equal(previousVec, toVec);
    } else {
      if (!previousVec || !previous2Vec)
        return false;

      CGFloat t  = dynamicsThreshold / 5;

      const CGFloat *toValues = toVec->data();
      const CGFloat *previousValues = previousVec->data();
      const CGFloat *previous2Values = previous2Vec->data();

      for (NSUInteger idx = 0; idx < count; idx++) {
        if ((fabsf(toValues[idx] - previousValues[idx]) >= t) || (fabsf(previous2Values[idx] - previousValues[idx]) >= t)) {
          return false;
        }
      }
      return true;
    }
  }

  bool isDone() {
    if (_POPPropertyAnimationState::isDone()) {
      return true;
    }
    return solver->started() && (hasConverged() || solver->hasConverged());
  }

  void updatedDynamics()
  {
    if (NULL != solver) {
      solver->setConstants(dynamicsTension, dynamicsFriction, dynamicsMass);
    }
  }

  void updatedDynamicsThreshold()
  {
    _POPPropertyAnimationState::updatedDynamicsThreshold();
    if (NULL != solver) {
      solver->setThreshold(dynamicsThreshold);
    }
  }

  void updatedBouncinessAndSpeed() {
    [POPSpringAnimation convertBounciness:springBounciness speed:springSpeed toTension:&dynamicsTension friction:&dynamicsFriction mass:&dynamicsMass];
    updatedDynamics();
  }

  bool advance(CFTimeInterval time, CFTimeInterval dt, id obj) {
    // advance past not yet initialized animations
    if (NULL == currentVec) {
      return false;
    }

    CFTimeInterval localTime = time - startTime;

    Vector4d value = vector4d(currentVec);
    Vector4d toValue = vector4d(toVec);
    Vector4d velocity = vector4d(velocityVec);

    SSState4d state;
    state.p = toValue - value;

    // the solver assumes a spring of size zero
    // flip the velocity from user perspective to solver perspective
    state.v = velocity * -1;

    solver->advance(state, localTime, dt);
    value = toValue - state.p;

    // flip velocity back to user perspective
    velocity = state.v * -1;

    *currentVec = value;

    if (velocityVec) {
      *velocityVec = velocity;
    }

    clampCurrentValue();

    return true;
  }

  virtual void reset(bool all) {
    _POPPropertyAnimationState::reset(all);

    if (solver) {
      solver->setConstants(dynamicsTension, dynamicsFriction, dynamicsMass);
      solver->reset();
    }
  }
};

typedef struct _POPSpringAnimationState POPSpringAnimationState;
