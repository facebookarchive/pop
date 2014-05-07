/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <objc/runtime.h>
#include <unordered_map>

#import <Foundation/Foundation.h>

#import "POPVector.h"

enum POPValueType
{
  kPOPValueUnknown = 0,
  kPOPValueInteger,
  kPOPValueFloat,
  kPOPValuePoint,
  kPOPValueSize,
  kPOPValueRect,
  kPOPValueAffineTransform,
  kPOPValueTransform,
  kPOPValueRange,
  kPOPValueColor,
};

using namespace POP;

/**
 Returns value type based on objc type description, given list of supported value types and length.
 */
extern POPValueType POPSelectValueType(const char *objctype, const POPValueType *types, size_t length);

/**
 Returns value type based on objc object, given a list of supported value types and length.
 */
extern POPValueType POPSelectValueType(id obj, const POPValueType *types, size_t length);

/**
 Array of all value types.
 */
extern const POPValueType kPOPAnimatableAllTypes[9];

/**
 Array of all value types supported for animation.
 */
extern const POPValueType kPOPAnimatableSupportTypes[7];

/**
 Returns a string description of a value type.
 */
extern NSString *POPValueTypeToString(POPValueType t);

/**
 Returns a mutable dictionary of weak pointer keys to weak pointer values.
 */
extern CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToWeakPointer(NSUInteger capacity) CF_RETURNS_RETAINED;

/**
 Returns a mutable dictionary of weak pointer keys to weak pointer values.
 */
extern CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToStrongObject(NSUInteger capacity) CF_RETURNS_RETAINED;

/**
 Box a vector.
 */
extern id POPBox(VectorConstRef vec, POPValueType type, bool force = false);

/**
 Unbox a vector.
 */
extern VectorRef POPUnbox(id value, POPValueType &type, NSUInteger &count, bool validate);

/**
 Read/write block typedefs for convenience.
 */
typedef void(^pop_animatable_read_block)(id obj, CGFloat *value);
typedef void(^pop_animatable_write_block)(id obj, const CGFloat *value);

/**
 Read object value and return a Vector4r.
 */
NS_INLINE Vector4r read_values(pop_animatable_read_block read, id obj, size_t count)
{
  Vector4r vec = Vector4r::Zero();
  if (0 == count)
    return vec;

  read(obj, vec.data());

  return vec;
}

NS_INLINE NSString *POPStringFromBOOL(BOOL value)
{
  return value ? @"YES" : @"NO";
}
