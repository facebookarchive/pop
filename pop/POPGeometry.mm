/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPGeometry.h"

#if !TARGET_OS_IPHONE
@implementation NSValue (POP)

+ (NSValue *)valueWithCGPoint:(CGPoint)point {
  return [NSValue valueWithBytes:&point objCType:@encode(CGPoint)];
}

+ (NSValue *)valueWithCGSize:(CGSize)size {
  return [NSValue valueWithBytes:&size objCType:@encode(CGSize)];
}

+ (NSValue *)valueWithCGRect:(CGRect)rect {
  return [NSValue valueWithBytes:&rect objCType:@encode(CGRect)];
}

+ (NSValue *)valueWithCFRange:(CFRange)range {
  return [NSValue valueWithBytes:&range objCType:@encode(CFRange)];
}

+ (NSValue *)valueWithCGAffineTransform:(CGAffineTransform)transform
{
  return [NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)];
}

- (CGPoint)CGPointValue {
  CGPoint result;
  [self getValue:&result];
  return result;
}

- (CGSize)CGSizeValue {
  CGSize result;
  [self getValue:&result];
  return result;
}

- (CGRect)CGRectValue {
  CGRect result;
  [self getValue:&result];
  return result;
}

- (CFRange)CFRangeValue {
  CFRange result;
  [self getValue:&result];
  return result;
}

- (CGAffineTransform)CGAffineTransformValue {
  CGAffineTransform result;
  [self getValue:&result];
  return result;
}
@end

#endif
