/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPMath.h"
#import "UnitBezier.h"
#import "POPAnimationPrivate.h"

void interpolate_vector(NSUInteger count, CGFloat *dst, const CGFloat *from, const CGFloat *to, double f)
{
  for (NSUInteger idx = 0; idx < count; idx++) {
    dst[idx] = MIX(from[idx], to[idx], f);
  }
}

double timing_function_solve(const double vec[4], double t, double eps)
{
  WebCore::UnitBezier bezier(vec[0], vec[1], vec[2], vec[3]);
  return bezier.solve(t, eps);
}

double normalize(double value, double startValue, double endValue)
{
  return (value - startValue) / (endValue - startValue);
}

double project_normal(double n, double start, double end)
{
  return start + (n * (end - start));
}

static double linear_interpolation(double t, double start, double end)
{
  return t * end + (1.f - t) * start;
}

double quadratic_out_interpolation(double t, double start, double end)
{
  return linear_interpolation(2*t - t*t, start, end);
}

static double b3_friction1(double x)
{
  return (0.0007 * pow(x, 3)) - (0.031 * pow(x, 2)) + 0.64 * x + 1.28;
}

static double b3_friction2(double x)
{
  return (0.000044 * pow(x, 3)) - (0.006 * pow(x, 2)) + 0.36 * x + 2.;
}

static double b3_friction3(double x)
{
  return (0.00000045 * pow(x, 3)) - (0.000332 * pow(x, 2)) + 0.1078 * x + 5.84;
}

double b3_nobounce(double tension)
{
  double friction = 0;
  if (tension <= 18.) {
    friction = b3_friction1(tension);
  } else if (tension > 18 && tension <= 44) {
    friction = b3_friction2(tension);
  } else if (tension > 44) {
    friction = b3_friction3(tension);
  } else {
    assert(false);
  }
  return friction;
}

void quadratic_solve(CGFloat a, CGFloat b, CGFloat c, CGFloat &x1, CGFloat &x2)
{
  CGFloat discriminant = sqrt(b * b - 4 * a * c);
  x1 = (-b + discriminant) / (2 * a);
  x2 = (-b - discriminant) / (2 * a);
}
