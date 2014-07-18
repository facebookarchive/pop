/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/NSObject.h>

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
+ (id)propertyWithName:(NSString *)name;

/**
 @abstract The designated initializer.
 @param name The name of the property.
 @param block The block used to configure the property on creation.
 @return The animatable property with name if it exists, otherwise a newly created instance configured by block.
 @discussion Custom properties should use reverse-DNS naming. A newly created instance is only mutable in the scope of block. Once constructed, a property becomes immutable.
 */
+ (id)propertyWithName:(NSString *)name initializer:(void (^)(POPMutableAnimatableProperty *prop))block;

/**
 @abstract The name of the property.
 @discussion Used to uniquely identify an animatable property.
 */
@property (readonly, nonatomic, copy) NSString *name;

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
@property (readwrite, nonatomic, copy) NSString *name;

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

/**
 Common CALayer property names.
 */
extern NSString * const kPOPLayerBackgroundColor;
extern NSString * const kPOPLayerBounds;
extern NSString * const kPOPLayerCornerRadius;
extern NSString * const kPOPLayerBorderWidth;
extern NSString * const kPOPLayerBorderColor;
extern NSString * const kPOPLayerOpacity;
extern NSString * const kPOPLayerPosition;
extern NSString * const kPOPLayerPositionX;
extern NSString * const kPOPLayerPositionY;
extern NSString * const kPOPLayerRotation;
extern NSString * const kPOPLayerRotationX;
extern NSString * const kPOPLayerRotationY;
extern NSString * const kPOPLayerScaleX;
extern NSString * const kPOPLayerScaleXY;
extern NSString * const kPOPLayerScaleY;
extern NSString * const kPOPLayerSize;
extern NSString * const kPOPLayerSubscaleXY;
extern NSString * const kPOPLayerSubtranslationX;
extern NSString * const kPOPLayerSubtranslationXY;
extern NSString * const kPOPLayerSubtranslationY;
extern NSString * const kPOPLayerSubtranslationZ;
extern NSString * const kPOPLayerTranslationX;
extern NSString * const kPOPLayerTranslationXY;
extern NSString * const kPOPLayerTranslationY;
extern NSString * const kPOPLayerTranslationZ;
extern NSString * const kPOPLayerZPosition;
extern NSString * const kPOPLayerShadowColor;
extern NSString * const kPOPLayerShadowOffset;
extern NSString * const kPOPLayerShadowOpacity;
extern NSString * const kPOPLayerShadowRadius;

/**
 Common CAShapeLayer property names.
 */
extern NSString * const kPOPShapeLayerStrokeStart;
extern NSString * const kPOPShapeLayerStrokeEnd;
extern NSString * const kPOPShapeLayerStrokeColor;
extern NSString * const kPOPShapeLayerFillColor;

/**
 Common NSLayoutConstraint property names.
 */
extern NSString * const kPOPLayoutConstraintConstant;


#if TARGET_OS_IPHONE

/**
 Common UIView property names.
 */
extern NSString * const kPOPViewAlpha;
extern NSString * const kPOPViewBackgroundColor;
extern NSString * const kPOPViewBounds;
extern NSString * const kPOPViewCenter;
extern NSString * const kPOPViewFrame;
extern NSString * const kPOPViewScaleX;
extern NSString * const kPOPViewScaleXY;
extern NSString * const kPOPViewScaleY;
extern NSString * const kPOPViewSize;
extern NSString * const kPOPViewTintColor;

/**
 Common UIScrollView property names.
 */
extern NSString * const kPOPScrollViewContentOffset;
extern NSString * const kPOPScrollViewContentSize;
extern NSString * const kPOPScrollViewZoomScale;
extern NSString * const kPOPScrollViewContentInset;

/**
 Common UITableView property names.
 */
extern NSString * const kPOPTableViewContentOffset;
extern NSString * const kPOPTableViewContentSize;

/**
 Common UICollectionView property names.
 */
extern NSString * const kPOPCollectionViewContentOffset;
extern NSString * const kPOPCollectionViewContentSize;

/**
 Common UINavigationBar property names.
 */
extern NSString * const kPOPNavigationBarBarTintColor;

/**
 Common UIToolbar property names.
 */
extern NSString * const kPOPToolbarBarTintColor;

/**
 Common UITabBar property names.
 */
extern NSString * const kPOPTabBarBarTintColor;

/**
 Common UILabel property names.
 */
extern NSString * const kPOPLabelTextColor;

#endif
