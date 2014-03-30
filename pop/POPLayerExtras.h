/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/QuartzCore.h>

#import <POP/POPDefines.h>

POP_EXTERN_C_BEGIN

#pragma mark - Scale

/**
 @abstract Returns layer scale factor for the x axis.
 */
extern CGFloat POPLayerGetScaleX(CALayer *l);

/**
 @abstract Set layer scale factor for the x axis.
 */
extern void POPLayerSetScaleX(CALayer *l, CGFloat f);

/**
 @abstract Returns layer scale factor for the y axis.
 */
extern CGFloat POPLayerGetScaleY(CALayer *l);

/**
 @abstract Set layer scale factor for the y axis.
 */
extern void POPLayerSetScaleY(CALayer *l, CGFloat f);

/**
 @abstract Returns layer scale factor for the z axis.
 */
extern CGFloat POPLayerGetScaleZ(CALayer *l);

/**
 @abstract Set layer scale factor for the z axis.
 */
extern void POPLayerSetScaleZ(CALayer *l, CGFloat f);

/**
 @abstract Returns layer scale factors for x and y access as point.
 */
extern CGPoint POPLayerGetScaleXY(CALayer *l);

/**
 @abstract Sets layer x and y scale factors given point.
 */
extern void POPLayerSetScaleXY(CALayer *l, CGPoint p);

#pragma mark - Translation

/**
 @abstract Returns layer translation factor for the x axis.
 */
extern CGFloat POPLayerGetTranslationX(CALayer *l);

/**
 @abstract Set layer translation factor for the x axis.
 */
extern void POPLayerSetTranslationX(CALayer *l, CGFloat f);

/**
 @abstract Returns layer translation factor for the y axis.
 */
extern CGFloat POPLayerGetTranslationY(CALayer *l);

/**
 @abstract Set layer translation factor for the y axis.
 */
extern void POPLayerSetTranslationY(CALayer *l, CGFloat f);

/**
 @abstract Returns layer translation factor for the z axis.
 */
extern CGFloat POPLayerGetTranslationZ(CALayer *l);

/**
 @abstract Set layer translation factor for the z axis.
 */
extern void POPLayerSetTranslationZ(CALayer *l, CGFloat f);

/**
 @abstract Returns layer translation factors for x and y access as point.
 */
extern CGPoint POPLayerGetTranslationXY(CALayer *l);

/**
 @abstract Sets layer x and y translation factors given point.
 */
extern void POPLayerSetTranslationXY(CALayer *l, CGPoint p);

#pragma mark - Rotation

/**
 @abstract Returns layer rotation, in radians, in the X axis.
 */
extern CGFloat POPLayerGetRotationX(CALayer *l);

/**
 @abstract Sets layer rotation, in radians, in the X axis.
 */
extern void POPLayerSetRotationX(CALayer *l, CGFloat f);

/**
 @abstract Returns layer rotation, in radians, in the Y axis.
 */
extern CGFloat POPLayerGetRotationY(CALayer *l);

/**
 @abstract Sets layer rotation, in radians, in the Y axis.
 */
extern void POPLayerSetRotationY(CALayer *l, CGFloat f);

/**
 @abstract Returns layer rotation, in radians, in the Z axis.
 */
extern CGFloat POPLayerGetRotationZ(CALayer *l);

/**
 @abstract Sets layer rotation, in radians, in the Z axis.
 */
extern void POPLayerSetRotationZ(CALayer *l, CGFloat f);

/**
 @abstract Returns layer rotation, in radians, in the Z axis.
 */
extern CGFloat POPLayerGetRotation(CALayer *l);

/**
 @abstract Sets layer rotation, in radians, in the Z axis.
 */
extern void POPLayerSetRotation(CALayer *l, CGFloat f);

#pragma mark - Sublayer Scale

/**
 @abstract Returns sublayer scale factors for x and y access as point.
 */
extern CGPoint POPLayerGetSubScaleXY(CALayer *l);

/**
 @abstract Sets sublayer x and y scale factors given point.
 */
extern void POPLayerSetSubScaleXY(CALayer *l, CGPoint p);

#pragma mark - Sublayer Translation

/**
 @abstract Returns sublayer translation factor for the x axis.
 */
extern CGFloat POPLayerGetSubTranslationX(CALayer *l);

/**
 @abstract Set sublayer translation factor for the x axis.
 */
extern void POPLayerSetSubTranslationX(CALayer *l, CGFloat f);

/**
 @abstract Returns sublayer translation factor for the y axis.
 */
extern CGFloat POPLayerGetSubTranslationY(CALayer *l);

/**
 @abstract Set sublayer translation factor for the y axis.
 */
extern void POPLayerSetSubTranslationY(CALayer *l, CGFloat f);

/**
 @abstract Returns sublayer translation factor for the z axis.
 */
extern CGFloat POPLayerGetSubTranslationZ(CALayer *l);

/**
 @abstract Set sublayer translation factor for the z axis.
 */
extern void POPLayerSetSubTranslationZ(CALayer *l, CGFloat f);

/**
 @abstract Returns sublayer translation factors for x and y access as point.
 */
extern CGPoint POPLayerGetSubTranslationXY(CALayer *l);

/**
 @abstract Sets sublayer x and y translation factors given point.
 */
extern void POPLayerSetSubTranslationXY(CALayer *l, CGPoint p);

POP_EXTERN_C_END
