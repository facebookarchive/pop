/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationRuntime.h"

#import <objc/objc.h>

#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIScreen.h>
#else
#import <AppKit/NSScreen.h>
#endif

#import "POPVector.h"
#import "POPAnimationRuntime.h"
#import "POPCGUtils.h"
#import "POPGeometry.h"

static Boolean pointerEqual(const void *ptr1, const void *ptr2) {
  return ptr1 == ptr2;
}

static CFHashCode pointerHash(const void *ptr) {
  return (CFHashCode)(ptr);
}

CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToWeakPointer(NSUInteger capacity)
{
  CFDictionaryKeyCallBacks kcb = kCFTypeDictionaryKeyCallBacks;

  // weak, pointer keys
  kcb.retain = NULL;
  kcb.retain = NULL;
  kcb.equal = pointerEqual;
  kcb.hash = pointerHash;

  CFDictionaryValueCallBacks vcb = kCFTypeDictionaryValueCallBacks;

  // weak, pointer values
  vcb.retain = NULL;
  vcb.release = NULL;
  vcb.equal = pointerEqual;

  return CFDictionaryCreateMutable(NULL, capacity, &kcb, &vcb);
}

CFMutableDictionaryRef POPDictionaryCreateMutableWeakPointerToStrongObject(NSUInteger capacity)
{
  CFDictionaryKeyCallBacks kcb = kCFTypeDictionaryKeyCallBacks;

  // weak, pointer keys
  kcb.retain = NULL;
  kcb.release = NULL;
  kcb.equal = pointerEqual;
  kcb.hash = pointerHash;

  // strong, object values
  CFDictionaryValueCallBacks vcb = kCFTypeDictionaryValueCallBacks;

  return CFDictionaryCreateMutable(NULL, capacity, &kcb, &vcb);
}

static bool FBCompareTypeEncoding(const char *objctype, POPValueType type)
{
  switch (type)
  {
    case kPOPValueFloat:
      return (strcmp(objctype, @encode(float)) == 0
              || strcmp(objctype, @encode(double)) == 0
              );

    case kPOPValuePoint:
      return (strcmp(objctype, @encode(CGPoint)) == 0
#if !TARGET_OS_IPHONE
              || strcmp(objctype, @encode(NSPoint)) == 0
#endif
              );

    case kPOPValueSize:
      return (strcmp(objctype, @encode(CGSize)) == 0
#if !TARGET_OS_IPHONE
              || strcmp(objctype, @encode(NSSize)) == 0
#endif
              );

    case kPOPValueRect:
      return (strcmp(objctype, @encode(CGRect)) == 0
#if !TARGET_OS_IPHONE
              || strcmp(objctype, @encode(NSRect)) == 0
#endif
              );

    case kPOPValueAffineTransform:
      return strcmp(objctype, @encode(CGAffineTransform)) == 0;

    case kPOPValueTransform:
      return strcmp(objctype, @encode(CATransform3D)) == 0;

    case kPOPValueRange:
      return strcmp(objctype, @encode(CFRange)) == 0
      || strcmp(objctype, @encode (NSRange)) == 0;

    case kPOPValueInteger:
      return (strcmp(objctype, @encode(int)) == 0
              || strcmp(objctype, @encode(unsigned int)) == 0
              || strcmp(objctype, @encode(short)) == 0
              || strcmp(objctype, @encode(unsigned short)) == 0
              || strcmp(objctype, @encode(long)) == 0
              || strcmp(objctype, @encode(unsigned long)) == 0
              || strcmp(objctype, @encode(long long)) == 0
              || strcmp(objctype, @encode(unsigned long long)) == 0
              );
    default:
      return false;
  }
}

POPValueType POPSelectValueType(const char *objctype, const POPValueType *types, size_t length)
{
  if (NULL != objctype) {
    for (size_t idx = 0; idx < length; idx++) {
      if (FBCompareTypeEncoding(objctype, types[idx]))
        return types[idx];
    }
  }
  return kPOPValueUnknown;
}

POPValueType POPSelectValueType(id obj, const POPValueType *types, size_t length)
{
  if ([obj isKindOfClass:[NSValue class]]) {
    return POPSelectValueType([obj objCType], types, length);
  } else if (NULL != POPCGColorWithColor(obj)) {
    return kPOPValueColor;
  }
  return kPOPValueUnknown;
}

const POPValueType kPOPAnimatableAllTypes[9] = {kPOPValueInteger, kPOPValueFloat, kPOPValuePoint, kPOPValueSize, kPOPValueRect, kPOPValueAffineTransform, kPOPValueTransform, kPOPValueRange, kPOPValueColor};

const POPValueType kPOPAnimatableSupportTypes[7] = {kPOPValueInteger, kPOPValueFloat, kPOPValuePoint, kPOPValueSize, kPOPValueRect, kPOPValueColor};

NSString *POPValueTypeToString(POPValueType t)
{
  switch (t) {
    case kPOPValueUnknown:
      return @"unknown";
    case kPOPValueInteger:
      return @"int";
    case kPOPValueFloat:
      return @"CGFloat";
    case kPOPValuePoint:
      return @"CGPoint";
    case kPOPValueSize:
      return @"CGSize";
    case kPOPValueRect:
      return @"CGRect";
    case kPOPValueAffineTransform:
      return @"CGAffineTransform";
    case kPOPValueTransform:
      return @"CATransform3D";
    case kPOPValueRange:
      return @"CFRange";
    case kPOPValueColor:
      return @"CGColorRef";
    default:
      return nil;
  }
}

id POPBox(VectorConstRef vec, POPValueType type, bool force)
{
  if (NULL == vec)
    return nil;
  
  switch (type) {
    case kPOPValueInteger:
    case kPOPValueFloat:
      return @(vec->data()[0]);
      break;
    case kPOPValuePoint:
      return [NSValue valueWithCGPoint:vec->cg_point()];
      break;
    case kPOPValueSize:
      return [NSValue valueWithCGSize:vec->cg_size()];
      break;
    case kPOPValueRect:
      return [NSValue valueWithCGRect:vec->cg_rect()];
      break;
    case kPOPValueColor: {
      return (__bridge_transfer id)vec->cg_color();
      break;
    }
    default:
      return force ? [NSValue valueWithCGPoint:vec->cg_point()] : nil;
      break;
  }
}

static VectorRef vectorize(id value, POPValueType type)
{
  Vector *vec = NULL;

  switch (type) {
    case kPOPValueInteger:
    case kPOPValueFloat:
      vec = Vector::new_cg_float([value floatValue]);
      break;
    case kPOPValuePoint:
      vec = Vector::new_cg_point([value CGPointValue]);
      break;
    case kPOPValueSize:
      vec = Vector::new_cg_size([value CGSizeValue]);
      break;
    case kPOPValueRect:
      vec = Vector::new_cg_rect([value CGRectValue]);
      break;
    case kPOPValueAffineTransform:
      vec = Vector::new_cg_affine_transform([value CGAffineTransformValue]);
      break;
    case kPOPValueColor:
      vec = Vector::new_cg_color(POPCGColorWithColor(value));
    default:
      break;
  }
  
  return VectorRef(vec);
}

VectorRef POPUnbox(id value, POPValueType &animationType, NSUInteger &count, bool validate)
{
  if (nil == value) {
    count = 0;
    return VectorRef(NULL);
  }

  // determine type of value
  POPValueType valueType = POPSelectValueType(value, kPOPAnimatableSupportTypes, POP_ARRAY_COUNT(kPOPAnimatableSupportTypes));

  // handle unknown types
  if (kPOPValueUnknown == valueType) {
    NSString *valueDesc = kPOPValueUnknown != valueType ? POPValueTypeToString(valueType) : [[value class] description];
    [NSException raise:@"Unsuported value" format:@"Animating %@ values is not supported", valueDesc];
  }

  // vectorize
  VectorRef vec = vectorize(value, valueType);

  if (kPOPValueUnknown == animationType || 0 == count) {
    // update animation type based on value type
    animationType = valueType;
    if (NULL != vec) {
      count = vec->size();
    }
  } else if (validate) {
    // allow for mismatched types, so long as vector size matches
    if (count != vec->size()) {
      [NSException raise:@"Invalid value" format:@"%@ should be of type %@", value, POPValueTypeToString(animationType)];
    }
  }
  
  return vec;
}
