/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPLayerExtras.h"

#include "TransformationMatrix.h"

using namespace WebCore;

#define DECOMPOSE_TRANSFORM(L) \
  TransformationMatrix _m(L.transform); \
  TransformationMatrix::DecomposedType _d; \
  _m.decompose(_d);

#define RECOMPOSE_TRANSFORM(L) \
  _m.recompose(_d); \
  L.transform = _m.transform3d();

#define RECOMPOSE_ROT_TRANSFORM(L) \
  _m.recompose(_d, true); \
  L.transform = _m.transform3d();

#define DECOMPOSE_SUBLAYER_TRANSFORM(L) \
  TransformationMatrix _m(L.sublayerTransform); \
  TransformationMatrix::DecomposedType _d; \
  _m.decompose(_d);

#define RECOMPOSE_SUBLAYER_TRANSFORM(L) \
  _m.recompose(_d); \
  L.sublayerTransform = _m.transform3d();

#pragma mark - Scale

CGFloat POPLayerGetScaleX(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.scaleX;
}

void POPLayerSetScaleX(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.scaleX = f;
  RECOMPOSE_TRANSFORM(l);
}

CGFloat POPLayerGetScaleY(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.scaleY;
}

void POPLayerSetScaleY(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.scaleY = f;
  RECOMPOSE_TRANSFORM(l);
}

CGFloat POPLayerGetScaleZ(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.scaleZ;
}

void POPLayerSetScaleZ(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.scaleZ = f;
  RECOMPOSE_TRANSFORM(l);
}

CGPoint POPLayerGetScaleXY(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return CGPointMake(_d.scaleX, _d.scaleY);
}

void POPLayerSetScaleXY(CALayer *l, CGPoint p)
{
  DECOMPOSE_TRANSFORM(l);
  _d.scaleX = p.x;
  _d.scaleY = p.y;
  RECOMPOSE_TRANSFORM(l);
}

#pragma mark - Translation

CGFloat POPLayerGetTranslationX(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.translateX;
}

void POPLayerSetTranslationX(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.translateX = f;
  RECOMPOSE_TRANSFORM(l);
}

CGFloat POPLayerGetTranslationY(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.translateY;
}

void POPLayerSetTranslationY(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.translateY = f;
  RECOMPOSE_TRANSFORM(l);
}

CGFloat POPLayerGetTranslationZ(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.translateZ;
}

void POPLayerSetTranslationZ(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.translateZ = f;
  RECOMPOSE_TRANSFORM(l);
}

CGPoint POPLayerGetTranslationXY(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return CGPointMake(_d.translateX, _d.translateY);
}

void POPLayerSetTranslationXY(CALayer *l, CGPoint p)
{
  DECOMPOSE_TRANSFORM(l);
  _d.translateX = p.x;
  _d.translateY = p.y;
  RECOMPOSE_TRANSFORM(l);
}

#pragma mark - Rotation

CGFloat POPLayerGetRotationX(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.rotateX;
}

void POPLayerSetRotationX(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.rotateX = f;
  RECOMPOSE_ROT_TRANSFORM(l);
}

CGFloat POPLayerGetRotationY(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.rotateY;
}

void POPLayerSetRotationY(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.rotateY = f;
  RECOMPOSE_ROT_TRANSFORM(l);
}

CGFloat POPLayerGetRotationZ(CALayer *l)
{
  DECOMPOSE_TRANSFORM(l);
  return _d.rotateZ;
}

void POPLayerSetRotationZ(CALayer *l, CGFloat f)
{
  DECOMPOSE_TRANSFORM(l);
  _d.rotateZ = f;
  RECOMPOSE_ROT_TRANSFORM(l);
}

CGFloat POPLayerGetRotation(CALayer *l)
{
  return POPLayerGetRotationZ(l);
}

void POPLayerSetRotation(CALayer *l, CGFloat f)
{
  POPLayerSetRotationZ(l, f);
}

#pragma mark - Sublayer Scale

CGPoint POPLayerGetSubScaleXY(CALayer *l)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  return CGPointMake(_d.scaleX, _d.scaleY);
}

void POPLayerSetSubScaleXY(CALayer *l, CGPoint p)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  _d.scaleX = p.x;
  _d.scaleY = p.y;
  RECOMPOSE_SUBLAYER_TRANSFORM(l);
}

#pragma mark - Sublayer Translation

extern CGFloat POPLayerGetSubTranslationX(CALayer *l)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  return _d.translateX;
}

extern void POPLayerSetSubTranslationX(CALayer *l, CGFloat f)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  _d.translateX = f;
  RECOMPOSE_SUBLAYER_TRANSFORM(l);
}

extern CGFloat POPLayerGetSubTranslationY(CALayer *l)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  return _d.translateY;
}

extern void POPLayerSetSubTranslationY(CALayer *l, CGFloat f)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  _d.translateY = f;
  RECOMPOSE_SUBLAYER_TRANSFORM(l);
}

extern CGFloat POPLayerGetSubTranslationZ(CALayer *l)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  return _d.translateZ;
}

extern void POPLayerSetSubTranslationZ(CALayer *l, CGFloat f)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  _d.translateZ = f;
  RECOMPOSE_SUBLAYER_TRANSFORM(l);
}

extern CGPoint POPLayerGetSubTranslationXY(CALayer *l)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  return CGPointMake(_d.translateX, _d.translateY);
}

extern void POPLayerSetSubTranslationXY(CALayer *l, CGPoint p)
{
  DECOMPOSE_SUBLAYER_TRANSFORM(l);
  _d.translateX = p.x;
  _d.translateY = p.y;
  RECOMPOSE_SUBLAYER_TRANSFORM(l);
}
