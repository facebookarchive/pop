/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPVector.h"
#import "POPCGUtils.h"

namespace POP
{

  Vector::Vector(const size_t count)
  {
    _count = count;
    _values = 0 != count ? (CGFloat *)calloc(count, sizeof(CGFloat)) : NULL;
  }

  Vector::Vector(const Vector& other)
  {
    _count = other.size();
    _values = 0 != _count ? (CGFloat *)calloc(_count, sizeof(CGFloat)) : NULL;
    if (0 != _count) {
      memcpy(_values, other.data(), _count * sizeof(CGFloat));
    }
  }

  Vector::~Vector()
  {
    if (NULL != _values) {
      free(_values);
      _values = NULL;
    }
    _count = 0;
  }

  void Vector::swap(Vector &first, Vector &second)
  {
    using std::swap;
    swap(first._count, second._count);
    swap(first._values, second._values);
  }

  Vector& Vector::operator=(const Vector& other)
  {
    Vector temp(other);
    swap(*this, temp);
    return *this;
  }

  bool Vector::operator==(const Vector &other) const {
    if (_count != other.size()) {
      return false;
    }

    const CGFloat * const values = other.data();

    for (NSUInteger idx = 0; idx < _count; idx++) {
      if (_values[idx] != values[idx]) {
        return false;
      }
    }

    return true;
  }

  bool Vector::operator!=(const Vector &other) const {
    if (_count == other.size()) {
      return false;
    }

    const CGFloat * const values = other.data();

    for (NSUInteger idx = 0; idx < _count; idx++) {
      if (_values[idx] != values[idx]) {
        return false;
      }
    }

    return true;
  }

  Vector *Vector::new_vector(NSUInteger count, const CGFloat *values)
  {
    if (0 == count) {
      return NULL;
    }

    Vector *v = new Vector(count);
    if (NULL != values) {
      memcpy(v->_values, values, count * sizeof(CGFloat));
    }
    return v;
  }

  Vector *Vector::new_vector(const Vector * const other)
  {
    if (NULL == other) {
      return NULL;
    }

    return Vector::new_vector(other->size(), other->data());
  }

  Vector *Vector::new_vector(NSUInteger count, Vector4r vec)
  {
    if (0 == count) {
      return NULL;
    }

    Vector *v = new Vector(count);

    NSCAssert(count <= 4, @"unexpected count %lu", (unsigned long)count);
    for (NSUInteger i = 0; i < MIN(count, (NSUInteger)4); i++) {
      v->_values[i] = vec[i];
    }

    return v;
  }

  Vector4r Vector::vector4r() const
  {
    Vector4r v = Vector4r::Zero();
    for (size_t i = 0; i < _count; i++) {
      v(i) = _values[i];
    }
    return v;
  }

  Vector2r Vector::vector2r() const
  {
    Vector2r v = Vector2r::Zero();
    if (_count > 0) v(0) = _values[0];
    if (_count > 1) v(1) = _values[1];
    return v;
  }

  Vector *Vector::new_cg_float(CGFloat f)
  {
    Vector *v = new Vector(1);
    v->_values[0] = f;
    return v;
  }

  CGPoint Vector::cg_point () const
  {
    Vector2r v = vector2r();
    return CGPointMake(v(0), v(1));
  }

  Vector *Vector::new_cg_point(const CGPoint &p)
  {
    Vector *v = new Vector(2);
    v->_values[0] = p.x;
    v->_values[1] = p.y;
    return v;
  }

  CGSize Vector::cg_size () const
  {
    Vector2r v = vector2r();
    return CGSizeMake(v(0), v(1));
  }

  Vector *Vector::new_cg_size(const CGSize &s)
  {
    Vector *v = new Vector(2);
    v->_values[0] = s.width;
    v->_values[1] = s.height;
    return v;
  }

  CGRect Vector::cg_rect() const
  {
    return _count < 4 ? CGRectZero : CGRectMake(_values[0], _values[1], _values[2], _values[3]);
  }

  Vector *Vector::new_cg_rect(const CGRect &r)
  {
    Vector *v = new Vector(4);
    v->_values[0] = r.origin.x;
    v->_values[1] = r.origin.y;
    v->_values[2] = r.size.width;
    v->_values[3] = r.size.height;
    return v;
  }

#if TARGET_OS_IPHONE

  UIEdgeInsets Vector::ui_edge_insets() const
  {
    return _count < 4 ? UIEdgeInsetsZero : UIEdgeInsetsMake(_values[0], _values[1], _values[2], _values[3]);
  }

  Vector *Vector::new_ui_edge_insets(const UIEdgeInsets &i)
  {
    Vector *v = new Vector(4);
    v->_values[0] = i.top;
    v->_values[1] = i.left;
    v->_values[2] = i.bottom;
    v->_values[3] = i.right;
    return v;
  }

#endif

  CGAffineTransform Vector::cg_affine_transform() const
  {
    if (_count < 6) {
      return CGAffineTransformIdentity;
    }

    NSCAssert(size() >= 6, @"unexpected vector size:%lu", (unsigned long)size());
    CGAffineTransform t;
    t.a = _values[0];
    t.b = _values[1];
    t.c = _values[2];
    t.d = _values[3];
    t.tx = _values[4];
    t.ty = _values[5];
    return t;
  }

  Vector *Vector::new_cg_affine_transform(const CGAffineTransform &t)
  {
    Vector *v = new Vector(6);
    v->_values[0] = t.a;
    v->_values[1] = t.b;
    v->_values[2] = t.c;
    v->_values[3] = t.d;
    v->_values[4] = t.tx;
    v->_values[5] = t.ty;
    return v;
  }

  CGColorRef Vector::cg_color() const
  {
    if (_count < 4) {
      return NULL;
    }
    return POPCGColorRGBACreate(_values);
  }

  Vector *Vector::new_cg_color(CGColorRef color)
  {
    CGFloat rgba[4];
    POPCGColorGetRGBAComponents(color, rgba);
    return new_vector(4, rgba);
  }

  void Vector::subRound(CGFloat sub)
  {
    for (NSUInteger idx = 0; idx < _count; idx++) {
      _values[idx] = POPSubRound(_values[idx], sub);
    }
  }

  CGFloat Vector::norm() const
  {
    return sqrtr(squaredNorm());
  }

  CGFloat Vector::squaredNorm() const
  {
    CGFloat d = 0;
    for (NSUInteger idx = 0; idx < _count; idx++) {
      d += (_values[idx] * _values[idx]);
    }
    return d;
  }

  NSString * Vector::toString() const
  {
    if (0 == _count)
      return @"()";

    if (1 == _count)
      return [NSString stringWithFormat:@"%f", _values[0]];

    if (2 == _count)
      return [NSString stringWithFormat:@"(%.3f, %.3f)", _values[0], _values[1]];

    NSMutableString *s = [NSMutableString stringWithCapacity:10];

    for (NSUInteger idx = 0; idx < _count; idx++) {
      if (0 == idx) {
        [s appendFormat:@"[%.3f", _values[idx]];
      } else if (idx == _count - 1) {
        [s appendFormat:@", %.3f]", _values[idx]];
      } else {
        [s appendFormat:@", %.3f", _values[idx]];
      }
    }

    return s;

  }
}
