/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.

 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef __POP__FBVector__
#define __POP__FBVector__

#include <iostream>
#include <vector>

#import <CoreGraphics/CoreGraphics.h>
#import <objc/NSObjCRuntime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "POPMath.h"
#import "POPDefines.h"

#if SCENEKIT_SDK_AVAILABLE
#import <SceneKit/SceneKit.h>
#endif

namespace POP {

  /** Fixed two-size vector class */
  template <typename T>
  struct Vector2
  {
  private:
    typedef T Vector2<T>::* const _data[2];
    static const _data _v;

  public:
    T x;
    T y;

    // Zero vector
    static const Vector2 Zero() { return Vector2(0); }

    // Constructors
    Vector2() {}
    explicit Vector2(T v) { x = v; y = v; };
    explicit Vector2(T x0, T y0) : x(x0), y(y0) {};
    explicit Vector2(const CGPoint &p) : x(p.x), y (p.y) {}
    explicit Vector2(const CGSize &s) : x(s.width), y (s.height) {}

    // Copy constructor
    template<typename U> explicit Vector2(const Vector2<U> &v) : x(v.x), y(v.y) {}

    // Index operators
    const T& operator[](size_t i) const { return this->*_v[i]; }
    T& operator[](size_t i) { return this->*_v[i]; }
    const T& operator()(size_t i) const { return this->*_v[i]; }
    T& operator()(size_t i) { return this->*_v[i]; }

    // Backing data
    T * data() { return &(this->*_v[0]); }
    const T * data() const { return &(this->*_v[0]); }

    // Size
    inline size_t size() const { return 2; }

    // Assignment
    Vector2 &operator= (T v) { x = v; y = v; return *this;}
    template<typename U> Vector2 &operator= (const Vector2<U> &v) { x = v.x; y = v.y; return *this;}

    // Negation
    Vector2 operator- (void) const { return Vector2<T>(-x, -y); }

    // Equality
    bool operator== (T v) const { return (x == v && y == v); }
    bool operator== (const Vector2 &v) const { return (x == v.x && y == v.y); }

    // Inequality
    bool operator!= (T v) const {return (x != v || y != v); }
    bool operator!= (const Vector2 &v) const { return (x != v.x || y != v.y); }

    // Scalar Math
    Vector2 operator+ (T v) const { return Vector2(x + v, y + v); }
    Vector2 operator- (T v) const { return Vector2(x - v, y - v); }
    Vector2 operator* (T v) const { return Vector2(x * v, y * v); }
    Vector2 operator/ (T v) const { return Vector2(x / v, y / v); }
    Vector2 &operator+= (T v) { x += v; y += v; return *this; };
    Vector2 &operator-= (T v) { x -= v; y -= v; return *this; };
    Vector2 &operator*= (T v) { x *= v; y *= v; return *this; };
    Vector2 &operator/= (T v) { x /= v; y /= v; return *this; };

    // Vector Math
    Vector2 operator+ (const Vector2 &v) const { return Vector2(x + v.x, y + v.y); }
    Vector2 operator- (const Vector2 &v) const { return Vector2(x - v.x, y - v.y); }
    Vector2 &operator+= (const Vector2 &v) { x += v.x; y += v.y; return *this; };
    Vector2 &operator-= (const Vector2 &v) { x -= v.x; y -= v.y; return *this; };

    // Norms
    CGFloat norm() const { return sqrtr(squaredNorm()); }
    CGFloat squaredNorm() const { return x * x + y * y; }

    // Cast
    template<typename U> Vector2<U> cast() const { return Vector2<U>(x, y); }
    CGPoint cg_point() const { return CGPointMake(x, y); };
  };

  template<typename T>
  const typename Vector2<T>::_data Vector2<T>::_v = { &Vector2<T>::x, &Vector2<T>::y };

  /** Fixed three-size vector class */
  template <typename T>
  struct Vector3
  {
  private:
    typedef T Vector3<T>::* const _data[3];
    static const _data _v;

  public:
    T x;
    T y;
    T z;

    // Zero vector
    static const Vector3 Zero() { return Vector3(0); };

    // Constructors
    Vector3() {}
    explicit Vector3(T v) : x(v), y(v), z(v) {};
    explicit Vector3(T x0, T y0, T z0) : x(x0), y(y0), z(z0) {};

    // Copy constructor
    template<typename U> explicit Vector3(const Vector3<U> &v) : x(v.x), y(v.y), z(v.z) {}

    // Index operators
    const T& operator[](size_t i) const { return this->*_v[i]; }
    T& operator[](size_t i) { return this->*_v[i]; }
    const T& operator()(size_t i) const { return this->*_v[i]; }
    T& operator()(size_t i) { return this->*_v[i]; }

    // Backing data
    T * data() { return &(this->*_v[0]); }
    const T * data() const { return &(this->*_v[0]); }

    // Size
    inline size_t size() const { return 3; }

    // Assignment
    Vector3 &operator= (T v) { x = v; y = v; z = v; return *this;}
    template<typename U> Vector3 &operator= (const Vector3<U> &v) { x = v.x; y = v.y; z = v.z; return *this;}

    // Negation
    Vector3 operator- (void) const { return Vector3<T>(-x, -y, -z); }

    // Equality
    bool operator== (T v) const { return (x == v && y == v && z = v); }
    bool operator== (const Vector3 &v) const { return (x == v.x && y == v.y && z == v.z); }

    // Inequality
    bool operator!= (T v) const {return (x != v || y != v || z != v); }
    bool operator!= (const Vector3 &v) const { return (x != v.x || y != v.y || z != v.z); }

    // Scalar Math
    Vector3 operator+ (T v) const { return Vector3(x + v, y + v, z + v); }
    Vector3 operator- (T v) const { return Vector3(x - v, y - v, z - v); }
    Vector3 operator* (T v) const { return Vector3(x * v, y * v, z * v); }
    Vector3 operator/ (T v) const { return Vector3(x / v, y / v, z / v); }
    Vector3 &operator+= (T v) { x += v; y += v; z += v; return *this; };
    Vector3 &operator-= (T v) { x -= v; y -= v; z -= v; return *this; };
    Vector3 &operator*= (T v) { x *= v; y *= v; z *= v; return *this; };
    Vector3 &operator/= (T v) { x /= v; y /= v; z /= v; return *this; };

    // Vector Math
    Vector3 operator+ (const Vector3 &v) const { return Vector3(x + v.x, y + v.y, z + v.z); }
    Vector3 operator- (const Vector3 &v) const { return Vector3(x - v.x, y - v.y, z - v.z); }
    Vector3 &operator+= (const Vector3 &v) { x += v.x; y += v.y; z += v.z; return *this; };
    Vector3 &operator-= (const Vector3 &v) { x -= v.x; y -= v.y; z -= v.z; return *this; };

    // Norms
    CGFloat norm() const { return sqrtr(squaredNorm()); }
    CGFloat squaredNorm() const { return x * x + y * y + z * z; }

    // Cast
    template<typename U> Vector3<U> cast() const { return Vector3<U>(x, y, z); }
  };

  template<typename T>
  const typename Vector3<T>::_data Vector3<T>::_v = { &Vector3<T>::x, &Vector3<T>::y, &Vector3<T>::z };

  /** Fixed four-size vector class */
  template <typename T>
  struct Vector4
  {
  private:
    typedef T Vector4<T>::* const _data[4];
    static const _data _v;

  public:
    T x;
    T y;
    T z;
    T w;

    // Zero vector
    static const Vector4 Zero() { return Vector4(0); };

    // Constructors
    Vector4() {}
    explicit Vector4(T v) : x(v), y(v), z(v), w(v) {};
    explicit Vector4(T x0, T y0, T z0, T w0) : x(x0), y(y0), z(z0), w(w0) {};

    // Copy constructor
    template<typename U> explicit Vector4(const Vector4<U> &v) : x(v.x), y(v.y), z(v.z), w(v.w) {}

    // Index operators
    const T& operator[](size_t i) const { return this->*_v[i]; }
    T& operator[](size_t i) { return this->*_v[i]; }
    const T& operator()(size_t i) const { return this->*_v[i]; }
    T& operator()(size_t i) { return this->*_v[i]; }

    // Backing data
    T * data() { return &(this->*_v[0]); }
    const T * data() const { return &(this->*_v[0]); }

    // Size
    inline size_t size() const { return 4; }

    // Assignment
    Vector4 &operator= (T v) { x = v; y = v; z = v; w = v; return *this;}
    template<typename U> Vector4 &operator= (const Vector4<U> &v) { x = v.x; y = v.y; z = v.z; w = v.w; return *this;}

    // Negation
    Vector4 operator- (void) const { return Vector4<T>(-x, -y, -z, -w); }

    // Equality
    bool operator== (T v) const { return (x == v && y == v && z = v, w = v); }
    bool operator== (const Vector4 &v) const { return (x == v.x && y == v.y && z == v.z && w == v.w); }

    // Inequality
    bool operator!= (T v) const {return (x != v || y != v || z != v || w != v); }
    bool operator!= (const Vector4 &v) const { return (x != v.x || y != v.y || z != v.z || w != v.w); }

    // Scalar Math
    Vector4 operator+ (T v) const { return Vector4(x + v, y + v, z + v, w + v); }
    Vector4 operator- (T v) const { return Vector4(x - v, y - v, z - v, w - v); }
    Vector4 operator* (T v) const { return Vector4(x * v, y * v, z * v, w * v); }
    Vector4 operator/ (T v) const { return Vector4(x / v, y / v, z / v, w / v); }
    Vector4 &operator+= (T v) { x += v; y += v; z += v; w += v; return *this; };
    Vector4 &operator-= (T v) { x -= v; y -= v; z -= v; w -= v; return *this; };
    Vector4 &operator*= (T v) { x *= v; y *= v; z *= v; w *= v; return *this; };
    Vector4 &operator/= (T v) { x /= v; y /= v; z /= v; w /= v; return *this; };

    // Vector Math
    Vector4 operator+ (const Vector4 &v) const { return Vector4(x + v.x, y + v.y, z + v.z, w + v.w); }
    Vector4 operator- (const Vector4 &v) const { return Vector4(x - v.x, y - v.y, z - v.z, w - v.w); }
    Vector4 &operator+= (const Vector4 &v) { x += v.x; y += v.y; z += v.z; w += v.w; return *this; };
    Vector4 &operator-= (const Vector4 &v) { x -= v.x; y -= v.y; z -= v.z; w -= v.w; return *this; };

    // Norms
    CGFloat norm() const { return sqrtr(squaredNorm()); }
    CGFloat squaredNorm() const { return x * x + y * y + z * z + w * w; }

    // Cast
    template<typename U> Vector4<U> cast() const { return Vector4<U>(x, y, z, w); }
  };

  template<typename T>
  const typename Vector4<T>::_data Vector4<T>::_v = { &Vector4<T>::x, &Vector4<T>::y, &Vector4<T>::z, &Vector4<T>::w };

  /** Convenience typedefs */
  typedef Vector2<float> Vector2f;
  typedef Vector2<double> Vector2d;
  typedef Vector2<CGFloat> Vector2r;
  typedef Vector3<float> Vector3f;
  typedef Vector3<double> Vector3d;
  typedef Vector3<CGFloat> Vector3r;
  typedef Vector4<float> Vector4f;
  typedef Vector4<double> Vector4d;
  typedef Vector4<CGFloat> Vector4r;

  /** Variable-sized vector class */
  class Vector
  {
    size_t _count;
    CGFloat *_values;

  private:
    Vector(size_t);
    Vector(const Vector& other);

  public:
    ~Vector();

    // Creates a new vector instance of count with values. Initializing a vector of size 0 returns NULL.
    static Vector *new_vector(NSUInteger count, const CGFloat *values);

    // Creates a new vector given a pointer to another. Can return NULL.
    static Vector *new_vector(const Vector * const other);

    // Creates a variable size vector given a static vector and count.
    static Vector *new_vector(NSUInteger count, Vector4r vec);

    // Size of vector
    NSUInteger size() const { return _count; }

    // Returns array of values
    CGFloat *data () { return _values; }
    const CGFloat *data () const { return _values; };

    // Vector2r support
    Vector2r vector2r() const;

    // Vector4r support
    Vector4r vector4r() const;

    // CGFloat support
    static Vector *new_cg_float(CGFloat f);

    // CGPoint support
    CGPoint cg_point() const;
    static Vector *new_cg_point(const CGPoint &p);

    // CGSize support
    CGSize cg_size() const;
    static Vector *new_cg_size(const CGSize &s);

    // CGRect support
    CGRect cg_rect() const;
    static Vector *new_cg_rect(const CGRect &r);

#if TARGET_OS_IPHONE
    // UIEdgeInsets support
    UIEdgeInsets ui_edge_insets() const;
    static Vector *new_ui_edge_insets(const UIEdgeInsets &i);
#endif

    // CGAffineTransform support
    CGAffineTransform cg_affine_transform() const;
    static Vector *new_cg_affine_transform(const CGAffineTransform &t);

    // CGColorRef support
    CGColorRef cg_color() const CF_RETURNS_RETAINED;
    static Vector *new_cg_color(CGColorRef color);
    
#if SCENEKIT_SDK_AVAILABLE
    // SCNVector3 support
    SCNVector3 scn_vector3() const;
    static Vector *new_scn_vector3(const SCNVector3 &vec3);
    
    // SCNVector4 support
    SCNVector4 scn_vector4() const;
    static Vector *new_scn_vector4(const SCNVector4 &vec4);
#endif

    // operator overloads
    CGFloat &operator[](size_t i) const {
      NSCAssert(size() > i, @"unexpected vector size:%lu", (unsigned long)size());
      return _values[i];
    }

    // Returns the mathematical length
    CGFloat norm() const;
    CGFloat squaredNorm() const;

    // Round to nearest sub
    void subRound(CGFloat sub);

    // Returns string description
    NSString * toString() const;

    // Operator overloads
    template<typename U> Vector& operator= (const Vector4<U>& other) {
      size_t count = MIN(_count, other.size());
      for (size_t i = 0; i < count; i++) {
        _values[i] = other[i];
      }
      return *this;
    }
    Vector& operator= (const Vector& other);
    void swap(Vector &first, Vector &second);
    bool operator==(const Vector &other) const;
    bool operator!=(const Vector &other) const;
  };

  /** Convenience typedefs */
  typedef std::shared_ptr<Vector> VectorRef;
  typedef std::shared_ptr<const Vector> VectorConstRef;

}
#endif /* defined(__POP__FBVector__) */
