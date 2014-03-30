/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIGeometry.h>
#endif

#if !TARGET_OS_IPHONE

/** NSValue extensions to support animatable types. */
@interface NSValue (POP)

/**
 @abstract Creates an NSValue given a CGPoint.
 */
+ (NSValue *)valueWithCGPoint:(CGPoint)point;

/**
 @abstract Creates an NSValue given a CGSize.
 */
+ (NSValue *)valueWithCGSize:(CGSize)size;

/**
 @abstract Creates an NSValue given a CGRect.
 */
+ (NSValue *)valueWithCGRect:(CGRect)rect;

/**
 @abstract Returns the underlying CGPoint value.
 */
- (CGPoint)CGPointValue;

/**
 @abstract Returns the underlying CGSize value.
 */
- (CGSize)CGSizeValue;

/**
 @abstract Returns the underlying CGRect value.
 */
- (CGRect)CGRectValue;

@end

#endif
