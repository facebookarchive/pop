/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "POPVector.h"

namespace POP {
  
  template <typename T>
  struct SSState
  {
    T p;
    T v;
  };
  
  template <typename T>
  struct SSDerivative
  {
    T dp;
    T dv;
  };
  
  typedef SSState<Vector4d> SSState4d;
  typedef SSDerivative<Vector4d> SSDerivative4d;
  
  const CFTimeInterval solverDt = 0.001f;
  const CFTimeInterval maxSolverDt = 30.0f;
  
  /**
   Templated spring solver class.
   */
  template <typename T>
  class SpringSolver
  {
    double _k; // stiffness
    double _b; // dampening
    double _m; // mass
    
    double _tp; // threshold
    double _tv; // threshold velocity
    double _ta; // threshold acceleration
    
    CFTimeInterval _accumulatedTime;
    SSState<T> _lastState;
    T _lastDv;
    bool _started;
    
  public:
    SpringSolver(double k, double b, double m = 1) : _k(k), _b(b), _m(m), _started(false)
    {
      _accumulatedTime = 0;
      _lastState.p = T::Zero();
      _lastState.v = T::Zero();
      _lastDv = T::Zero();
      setThreshold(1.);
    }
    
    ~SpringSolver()
    {
    }
    
    bool started()
    {
      return _started;
    }
    
    void setConstants(double k, double b, double m)
    {
      _k = k;
      _b = b;
      _m = m;
    }
    
    void setThreshold(double t)
    {
      _tp = t / 2;          // half a unit
      _tv = 25.0 * t;       // 5 units per second, squared for comparison
      _ta = 625.0 * t * t;  // 5 units per second squared, squared for comparison
    }
    
    T acceleration(const SSState<T> &state, double t)
    {
      return state.p*(-_k/_m) - state.v*(_b/_m);
    }
    
    SSDerivative<T> evaluate(const SSState<T> &initial, double t)
    {
      SSDerivative<T> output;
      output.dp = initial.v;
      output.dv = acceleration(initial, t);
      return output;
    }
    
    SSDerivative<T> evaluate(const SSState<T> &initial, double t, double dt, const SSDerivative<T> &d)
    {
      SSState<T> state;
      state.p = initial.p + d.dp*dt;
      state.v = initial.v + d.dv*dt;
      SSDerivative<T> output;
      output.dp = state.v;
      output.dv = acceleration(state, t+dt);
      return output;
    }
    
    void integrate(SSState<T> &state, double t, double dt)
    {
      SSDerivative<T> a = evaluate(state, t);
      SSDerivative<T> b = evaluate(state, t, dt*0.5, a);
      SSDerivative<T> c = evaluate(state, t, dt*0.5, b);
      SSDerivative<T> d = evaluate(state, t, dt, c);
      
      T dpdt = (a.dp + (b.dp + c.dp)*2.0 + d.dp) * (1.0/6.0);
      T dvdt = (a.dv + (b.dv + c.dv)*2.0 + d.dv) * (1.0/6.0);
      
      state.p = state.p + dpdt*dt;
      state.v = state.v + dvdt*dt;
      
      _lastDv = dvdt;
    }
    
    SSState<T> interpolate(const SSState<T> &previous, const SSState<T> &current, double alpha)
    {
      SSState<T> state;
      state.p = current.p*alpha + previous.p*(1-alpha);
      state.v = current.v*alpha + previous.v*(1-alpha);
      return state;
    }
    
    void advance(SSState<T> &state, double t, double dt)
    {
      _started = true;
      
      if (dt > maxSolverDt) {
        // excessive time step, force shut down
        _lastDv = _lastState.v = _lastState.p = T::Zero();
      } else {
        _accumulatedTime += dt;
        
        SSState<T> previousState = state, currentState = state;
        while (_accumulatedTime >= solverDt) {
          previousState = currentState;
          this->integrate(currentState, t, solverDt);
          t += solverDt;
          _accumulatedTime -= solverDt;
        }
        CFTimeInterval alpha = _accumulatedTime / solverDt;
        _lastState = state = this->interpolate(previousState, currentState, alpha);
      }
    }
    
    bool hasConverged()
    {
      if (!_started) {
        return false;
      }
      
      for (int idx = 0; idx < _lastState.p.size(); idx++) {
        if (fabs(_lastState.p(idx)) >= _tp) {
          return false;
        }
      }
      
      return (_lastState.v.squaredNorm() < _tv) && (_lastDv.squaredNorm() < _ta);
    }
    
    void reset()
    {
      _accumulatedTime = 0;
      _lastState.p = T::Zero();
      _lastState.v = T::Zero();
      _lastDv = T::Zero();
      _started = false;
    }
  };

  /**
   Convenience spring solver type definitions.
   */
  typedef SpringSolver<Vector2d> SpringSolver2d;
  typedef SpringSolver<Vector3d> SpringSolver3d;
  typedef SpringSolver<Vector4d> SpringSolver4d;
}

