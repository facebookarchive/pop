/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/NSObject.h>
#import "POPAnimatablePropertyTypes.h"

@class POPMutableAnimatableProperty;

/**
 @abstract Describes an animatable property.
 */
@interface POPAnimatableProperty : NSObject <NSCopying, NSMutableCopying>

/**
 @abstract Property accessor.
 @param name The name of the property.
 @return The animatable property with that name or nil if it does not exist.
 @discussion Common animatable properties are included by default. Use the provided constants to reference.
 */
+ (id)propertyWithType:(POPAnimatablePropertyType)type;
+ (id)propertyWithCustomProperty:(NSString *)customProperty;

/**
 @abstract The designated initializer.
 @param name The name of the property.
 @param block The block used to configure the property on creation.
 @return The animatable property with name if it exists, otherwise a newly created instance configured by block.
 @discussion Custom properties should use reverse-DNS naming. A newly created instance is only mutable in the scope of block. Once constructed, a property becomes immutable.
 */
+ (id)propertyWithType:(POPAnimatablePropertyType)type initializer:(void (^)(POPMutableAnimatableProperty *prop))block;

+ (id)propertyWithCustomProperty:(NSString *)customProperty initializer:(void (^)(POPMutableAnimatableProperty *prop))block;

/**
 @abstract The name of the property.
 @discussion Used to uniquely identify an animatable property.
 */
@property (readwrite, nonatomic, assign) POPAnimatablePropertyType type;

/**
 @abstract Block used to read values from a property into an array of floats.
 */
@property (readonly, nonatomic, copy) void (^readBlock)(id obj, CGFloat values[]);

/**
 @abstract Block used to write values from an array of floats into a property.
 */
@property (readonly, nonatomic, copy) void (^writeBlock)(id obj, const CGFloat values[]);

/**
 @abstract The threshold value used when determining completion of dynamics simulations.
 */
@property (readonly, nonatomic, assign) CGFloat threshold;

@end

/**
 @abstract A mutable animatable property intended for configuration.
 */
@interface POPMutableAnimatableProperty : POPAnimatableProperty

/**
 @abstract A read-write version of POPAnimatableProperty name property.
 */
@property (readwrite, nonatomic, assign) POPAnimatablePropertyType type;

/**
 @abstract A read-write version of POPAnimatableProperty readBlock property.
 */
@property (readwrite, nonatomic, copy) void (^readBlock)(id obj, CGFloat values[]);

/**
 @abstract A read-write version of POPAnimatableProperty writeBlock property.
 */
@property (readwrite, nonatomic, copy) void (^writeBlock)(id obj, const CGFloat values[]);

/**
 @abstract A read-write version of POPAnimatableProperty threshold property.
 */
@property (readwrite, nonatomic, assign) CGFloat threshold;

@end

