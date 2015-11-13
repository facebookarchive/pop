/**
  Copyright (c) 2014-present, Facebook, Inc.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimatableProperty.h"

#import <QuartzCore/QuartzCore.h>

#import "POPAnimationRuntime.h"
#import "POPCGUtils.h"
#import "POPDefines.h"
#import "POPLayerExtras.h"

// common threshold definitions
static CGFloat const kPOPThresholdColor = 0.01;
static CGFloat const kPOPThresholdPoint = 1.0;
static CGFloat const kPOPThresholdOpacity = 0.01;
static CGFloat const kPOPThresholdScale = 0.005;
static CGFloat const kPOPThresholdRotation = 0.01;
static CGFloat const kPOPThresholdRadius = 0.01;

#pragma mark - Static

// CALayer
NSString * const kPOPLayerBackgroundColor = @"backgroundColor";
NSString * const kPOPLayerBounds = @"bounds";
NSString * const kPOPLayerCornerRadius = @"cornerRadius";
NSString * const kPOPLayerBorderWidth = @"borderWidth";
NSString * const kPOPLayerBorderColor = @"borderColor";
NSString * const kPOPLayerOpacity = @"opacity";
NSString * const kPOPLayerPosition = @"position";
NSString * const kPOPLayerPositionX = @"positionX";
NSString * const kPOPLayerPositionY = @"positionY";
NSString * const kPOPLayerRotation = @"rotation";
NSString * const kPOPLayerRotationX = @"rotationX";
NSString * const kPOPLayerRotationY = @"rotationY";
NSString * const kPOPLayerScaleX = @"scaleX";
NSString * const kPOPLayerScaleXY = @"scaleXY";
NSString * const kPOPLayerScaleY = @"scaleY";
NSString * const kPOPLayerSize = @"size";
NSString * const kPOPLayerSubscaleXY = @"subscaleXY";
NSString * const kPOPLayerSubtranslationX = @"subtranslationX";
NSString * const kPOPLayerSubtranslationXY = @"subtranslationXY";
NSString * const kPOPLayerSubtranslationY = @"subtranslationY";
NSString * const kPOPLayerSubtranslationZ = @"subtranslationZ";
NSString * const kPOPLayerTranslationX = @"translationX";
NSString * const kPOPLayerTranslationXY = @"translationXY";
NSString * const kPOPLayerTranslationY = @"translationY";
NSString * const kPOPLayerTranslationZ = @"translationZ";
NSString * const kPOPLayerZPosition = @"zPosition";
NSString * const kPOPLayerShadowColor = @"shadowColor";
NSString * const kPOPLayerShadowOffset = @"shadowOffset";
NSString * const kPOPLayerShadowOpacity = @"shadowOpacity";
NSString * const kPOPLayerShadowRadius = @"shadowRadius";

// CAShapeLayer
NSString * const kPOPShapeLayerStrokeStart = @"shapeLayer.strokeStart";
NSString * const kPOPShapeLayerStrokeEnd = @"shapeLayer.strokeEnd";
NSString * const kPOPShapeLayerStrokeColor = @"shapeLayer.strokeColor";
NSString * const kPOPShapeLayerFillColor = @"shapeLayer.fillColor";
NSString * const kPOPShapeLayerLineWidth = @"shapeLayer.lineWidth";
NSString * const kPOPShapeLayerLineDashPhase = @"shapeLayer.lineDashPhase";

// NSLayoutConstraint
NSString * const kPOPLayoutConstraintConstant = @"layoutConstraint.constant";

#if TARGET_OS_IPHONE

// UIView
NSString * const kPOPViewAlpha = @"view.alpha";
NSString * const kPOPViewBackgroundColor = @"view.backgroundColor";
NSString * const kPOPViewBounds = kPOPLayerBounds;
NSString * const kPOPViewCenter = @"view.center";
NSString * const kPOPViewFrame = @"view.frame";
NSString * const kPOPViewScaleX = @"view.scaleX";
NSString * const kPOPViewScaleXY = @"view.scaleXY";
NSString * const kPOPViewScaleY = @"view.scaleY";
NSString * const kPOPViewSize = kPOPLayerSize;
NSString * const kPOPViewTintColor = @"view.tintColor";

// UIScrollView
NSString * const kPOPScrollViewContentOffset = @"scrollView.contentOffset";
NSString * const kPOPScrollViewContentSize = @"scrollView.contentSize";
NSString * const kPOPScrollViewZoomScale = @"scrollView.zoomScale";
NSString * const kPOPScrollViewContentInset = @"scrollView.contentInset";
NSString * const kPOPScrollViewScrollIndicatorInsets = @"scrollView.scrollIndicatorInsets";

// UITableView
NSString * const kPOPTableViewContentOffset = kPOPScrollViewContentOffset;
NSString * const kPOPTableViewContentSize = kPOPScrollViewContentSize;

// UICollectionView
NSString * const kPOPCollectionViewContentOffset = kPOPScrollViewContentOffset;
NSString * const kPOPCollectionViewContentSize = kPOPScrollViewContentSize;

// UINavigationBar
NSString * const kPOPNavigationBarBarTintColor = @"navigationBar.barTintColor";

// UIToolbar
NSString * const kPOPToolbarBarTintColor = kPOPNavigationBarBarTintColor;

// UITabBar
NSString * const kPOPTabBarBarTintColor = kPOPNavigationBarBarTintColor;

// UILabel
NSString * const kPOPLabelTextColor = @"label.textColor";

#else

// NSView
NSString * const kPOPViewFrame = @"view.frame";
NSString * const kPOPViewBounds = @"view.bounds";
NSString * const kPOPViewAlphaValue = @"view.alphaValue";
NSString * const kPOPViewFrameRotation = @"view.frameRotation";
NSString * const kPOPViewFrameCenterRotation = @"view.frameCenterRotation";
NSString * const kPOPViewBoundsRotation = @"view.boundsRotation";

// NSWindow
NSString * const kPOPWindowFrame = @"window.frame";
NSString * const kPOPWindowAlphaValue = @"window.alphaValue";
NSString * const kPOPWindowBackgroundColor = @"window.backgroundColor";

#endif

#if SCENEKIT_SDK_AVAILABLE

// SceneKit
NSString * const kPOPSCNNodePosition = @"scnode.position";
NSString * const kPOPSCNNodePositionX = @"scnnode.position.x";
NSString * const kPOPSCNNodePositionY = @"scnnode.position.y";
NSString * const kPOPSCNNodePositionZ = @"scnnode.position.z";
NSString * const kPOPSCNNodeTranslation = @"scnnode.translation";
NSString * const kPOPSCNNodeTranslationX = @"scnnode.translation.x";
NSString * const kPOPSCNNodeTranslationY = @"scnnode.translation.y";
NSString * const kPOPSCNNodeTranslationZ = @"scnnode.translation.z";
NSString * const kPOPSCNNodeRotation = @"scnnode.rotation";
NSString * const kPOPSCNNodeRotationX = @"scnnode.rotation.x";
NSString * const kPOPSCNNodeRotationY = @"scnnode.rotation.y";
NSString * const kPOPSCNNodeRotationZ = @"scnnode.rotation.z";
NSString * const kPOPSCNNodeRotationW = @"scnnode.rotation.w";
NSString * const kPOPSCNNodeEulerAngles = @"scnnode.eulerAngles";
NSString * const kPOPSCNNodeEulerAnglesX = @"scnnode.eulerAngles.x";
NSString * const kPOPSCNNodeEulerAnglesY = @"scnnode.eulerAngles.y";
NSString * const kPOPSCNNodeEulerAnglesZ = @"scnnode.eulerAngles.z";
NSString * const kPOPSCNNodeOrientation = @"scnnode.orientation";
NSString * const kPOPSCNNodeOrientationX = @"scnnode.orientation.x";
NSString * const kPOPSCNNodeOrientationY = @"scnnode.orientation.y";
NSString * const kPOPSCNNodeOrientationZ = @"scnnode.orientation.z";
NSString * const kPOPSCNNodeOrientationW = @"scnnode.orientation.w";
NSString * const kPOPSCNNodeScale = @"scnnode.scale";
NSString * const kPOPSCNNodeScaleX = @"scnnode.scale.x";
NSString * const kPOPSCNNodeScaleY = @"scnnode.scale.y";
NSString * const kPOPSCNNodeScaleZ = @"scnnode.scale.z";
NSString * const kPOPSCNNodeScaleXY = @"scnnode.scale.xy";

#endif

/**
 State structure internal to static animatable property.
 */
typedef struct
{
  NSString *name;
  pop_animatable_read_block readBlock;
  pop_animatable_write_block writeBlock;
  CGFloat threshold;
} _POPStaticAnimatablePropertyState;
typedef _POPStaticAnimatablePropertyState POPStaticAnimatablePropertyState;

static POPStaticAnimatablePropertyState _staticStates[] =
{
  /* CALayer */

  {kPOPLayerBackgroundColor,
    ^(CALayer *obj, CGFloat values[]) {
      POPCGColorGetRGBAComponents(obj.backgroundColor, values);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      CGColorRef color = POPCGColorRGBACreate(values);
      [obj setBackgroundColor:color];
      CGColorRelease(color);
    },
    kPOPThresholdColor
  },

  {kPOPLayerBounds,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_rect(values, [obj bounds]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setBounds:values_to_rect(values)];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerCornerRadius,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj cornerRadius];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setCornerRadius:values[0]];
    },
    kPOPThresholdRadius
  },

  {kPOPLayerBorderWidth,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj borderWidth];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setBorderWidth:values[0]];
    },
    0.01
  },

  {kPOPLayerBorderColor,
    ^(CALayer *obj, CGFloat values[]) {
      POPCGColorGetRGBAComponents(obj.borderColor, values);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      CGColorRef color = POPCGColorRGBACreate(values);
      [obj setBorderColor:color];
      CGColorRelease(color);
    },
    kPOPThresholdColor
  },

  {kPOPLayerPosition,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, [(CALayer *)obj position]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setPosition:values_to_point(values)];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerPositionX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [(CALayer *)obj position].x;
    },
    ^(CALayer *obj, const CGFloat values[]) {
      CGPoint p = [(CALayer *)obj position];
      p.x = values[0];
      [obj setPosition:p];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerPositionY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [(CALayer *)obj position].y;
    },
    ^(CALayer *obj, const CGFloat values[]) {
      CGPoint p = [(CALayer *)obj position];
      p.y = values[0];
      [obj setPosition:p];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerOpacity,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj opacity];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setOpacity:((float)values[0])];
    },
    kPOPThresholdOpacity
  },

  {kPOPLayerScaleX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleX(obj, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPLayerScaleY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleY(obj, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPLayerScaleXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetScaleXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleXY(obj, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {kPOPLayerSubscaleXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetSubScaleXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubScaleXY(obj, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {kPOPLayerTranslationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationX(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerTranslationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationY(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerTranslationZ,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationZ(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationZ(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerTranslationXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetTranslationXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationXY(obj, values_to_point(values));
    },
    kPOPThresholdPoint
  },

  {kPOPLayerSubtranslationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationX(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerSubtranslationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationY(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerSubtranslationZ,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationZ(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationZ(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {kPOPLayerSubtranslationXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetSubTranslationXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationXY(obj, values_to_point(values));
    },
    kPOPThresholdPoint
  },

  {kPOPLayerZPosition,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj zPosition];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setZPosition:values[0]];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerSize,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_size(values, [obj bounds].size);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      CGSize size = values_to_size(values);
      if (size.width < 0. || size.height < 0.)
        return;

      CGRect b = [obj bounds];
      b.size = size;
      [obj setBounds:b];
    },
    kPOPThresholdPoint
  },

  {kPOPLayerRotation,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotation(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetRotation(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {kPOPLayerRotationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotationY(obj);
    },
    ^(id obj, const CGFloat values[]) {
      POPLayerSetRotationY(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {kPOPLayerRotationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetRotationX(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {kPOPLayerShadowColor,
    ^(CALayer *obj, CGFloat values[]) {
        POPCGColorGetRGBAComponents(obj.shadowColor, values);
    },
    ^(CALayer *obj, const CGFloat values[]) {
        CGColorRef color = POPCGColorRGBACreate(values);
        [obj setShadowColor:color];
        CGColorRelease(color);
    },
    0.01
  },

  {kPOPLayerShadowOffset,
    ^(CALayer *obj, CGFloat values[]) {
        values_from_size(values, [obj shadowOffset]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
        CGSize size = values_to_size(values);
        [obj setShadowOffset:size];
    },
    0.01
  },

  {kPOPLayerShadowOpacity,
    ^(CALayer *obj, CGFloat values[]) {
        values[0] = [obj shadowOpacity];
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setShadowOpacity:values[0]];
    },
    kPOPThresholdOpacity
  },

  {kPOPLayerShadowRadius,
    ^(CALayer *obj, CGFloat values[]) {
        values[0] = [obj shadowRadius];
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setShadowRadius:values[0]];
    },
    kPOPThresholdRadius
  },

  /* CAShapeLayer */

  {kPOPShapeLayerStrokeStart,
    ^(CAShapeLayer *obj, CGFloat values[]) {
      values[0] = obj.strokeStart;
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
      obj.strokeStart = values[0];
    },
    0.01
  },

  {kPOPShapeLayerStrokeEnd,
    ^(CAShapeLayer *obj, CGFloat values[]) {
      values[0] = obj.strokeEnd;
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
      obj.strokeEnd = values[0];
    },
    0.01
  },

  {kPOPShapeLayerStrokeColor,
    ^(CAShapeLayer *obj, CGFloat values[]) {
        POPCGColorGetRGBAComponents(obj.strokeColor, values);
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
        CGColorRef color = POPCGColorRGBACreate(values);
        [obj setStrokeColor:color];
        CGColorRelease(color);
    },
    kPOPThresholdColor
  },

  {kPOPShapeLayerFillColor,
    ^(CAShapeLayer *obj, CGFloat values[]) {
        POPCGColorGetRGBAComponents(obj.fillColor, values);
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
        CGColorRef color = POPCGColorRGBACreate(values);
        [obj setFillColor:color];
        CGColorRelease(color);
    },
    kPOPThresholdColor
  },

  {kPOPShapeLayerLineWidth,
    ^(CAShapeLayer *obj, CGFloat values[]) {
        values[0] = obj.lineWidth;
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
        obj.lineWidth = values[0];
    },
    0.01
  },
    
    {kPOPShapeLayerLineDashPhase,
        ^(CAShapeLayer *obj, CGFloat values[]) {
            values[0] = obj.lineDashPhase;
        },
        ^(CAShapeLayer *obj, const CGFloat values[]) {
            obj.lineDashPhase = values[0];
        },
        0.01
    },

  {kPOPLayoutConstraintConstant,
    ^(NSLayoutConstraint *obj, CGFloat values[]) {
      values[0] = obj.constant;
    },
    ^(NSLayoutConstraint *obj, const CGFloat values[]) {
      obj.constant = values[0];
    },
    0.01
  },

#if TARGET_OS_IPHONE

  /* UIView */

  {kPOPViewAlpha,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = obj.alpha;
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.alpha = values[0];
    },
    kPOPThresholdOpacity
  },

  {kPOPViewBackgroundColor,
    ^(UIView *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.backgroundColor, values);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.backgroundColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

  {kPOPViewCenter,
    ^(UIView *obj, CGFloat values[]) {
      values_from_point(values, obj.center);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.center = values_to_point(values);
    },
    kPOPThresholdPoint
  },

  {kPOPViewFrame,
    ^(UIView *obj, CGFloat values[]) {
      values_from_rect(values, obj.frame);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.frame = values_to_rect(values);
    },
    kPOPThresholdPoint
  },

  {kPOPViewScaleX,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleX(obj.layer);
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleX(obj.layer, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPViewScaleY,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleY(obj.layer);
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleY(obj.layer, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPViewScaleXY,
    ^(UIView *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetScaleXY(obj.layer));
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleXY(obj.layer, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {kPOPViewTintColor,
    ^(UIView *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.tintColor, values);
    },
    ^(UIView *obj, const CGFloat values[]) {
        obj.tintColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

  /* UIScrollView */

  {kPOPScrollViewContentOffset,
    ^(UIScrollView *obj, CGFloat values[]) {
      values_from_point(values, obj.contentOffset);
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      [obj setContentOffset:values_to_point(values) animated:NO];
    },
    kPOPThresholdPoint
  },

  {kPOPScrollViewContentSize,
    ^(UIScrollView *obj, CGFloat values[]) {
      values_from_size(values, obj.contentSize);
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.contentSize = values_to_size(values);
    },
    kPOPThresholdPoint
  },

  {kPOPScrollViewZoomScale,
    ^(UIScrollView *obj, CGFloat values[]) {
      values[0]=obj.zoomScale;
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.zoomScale=values[0];
    },
    kPOPThresholdScale
  },

  {kPOPScrollViewContentInset,
    ^(UIScrollView *obj, CGFloat values[]) {
      values[0] = obj.contentInset.top;
      values[1] = obj.contentInset.left;
      values[2] = obj.contentInset.bottom;
      values[3] = obj.contentInset.right;
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.contentInset = values_to_edge_insets(values);
    },
    kPOPThresholdPoint
  },

  {kPOPScrollViewScrollIndicatorInsets,
    ^(UIScrollView *obj, CGFloat values[]) {
      values[0] = obj.scrollIndicatorInsets.top;
      values[1] = obj.scrollIndicatorInsets.left;
      values[2] = obj.scrollIndicatorInsets.bottom;
      values[3] = obj.scrollIndicatorInsets.right;
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.scrollIndicatorInsets = values_to_edge_insets(values);
    },
    kPOPThresholdPoint
  },

  /* UINavigationBar */

  {kPOPNavigationBarBarTintColor,
    ^(UINavigationBar *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.barTintColor, values);
    },
    ^(UINavigationBar *obj, const CGFloat values[]) {
      obj.barTintColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

  /* UILabel */

  {kPOPLabelTextColor,
    ^(UILabel *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.textColor, values);
    },
    ^(UILabel *obj, const CGFloat values[]) {
      obj.textColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

#else

  /* NSView */

  {kPOPViewFrame,
    ^(NSView *obj, CGFloat values[]) {
      values_from_rect(values, NSRectToCGRect(obj.frame));
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.frame = NSRectFromCGRect(values_to_rect(values));
    },
    kPOPThresholdPoint
  },

  {kPOPViewBounds,
    ^(NSView *obj, CGFloat values[]) {
      values_from_rect(values, NSRectToCGRect(obj.frame));
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.bounds = NSRectFromCGRect(values_to_rect(values));
    },
    kPOPThresholdPoint
  },

  {kPOPViewAlphaValue,
    ^(NSView *obj, CGFloat values[]) {
      values[0] = obj.alphaValue;
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.alphaValue = values[0];
    },
    kPOPThresholdOpacity
  },

  {kPOPViewFrameRotation,
    ^(NSView *obj, CGFloat values[]) {
      values[0] = obj.frameRotation;
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.frameRotation = values[0];
    },
    kPOPThresholdRotation
  },

  {kPOPViewFrameCenterRotation,
    ^(NSView *obj, CGFloat values[]) {
      values[0] = obj.frameCenterRotation;
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.frameCenterRotation = values[0];
    },
    kPOPThresholdRotation
  },

  {kPOPViewBoundsRotation,
    ^(NSView *obj, CGFloat values[]) {
      values[0] = obj.boundsRotation;
    },
    ^(NSView *obj, const CGFloat values[]) {
      obj.boundsRotation = values[0];
    },
    kPOPThresholdRotation
  },

  /* NSWindow */

  {kPOPWindowFrame,
    ^(NSWindow *obj, CGFloat values[]) {
      values_from_rect(values, NSRectToCGRect(obj.frame));
    },
    ^(NSWindow *obj, const CGFloat values[]) {
      [obj setFrame:NSRectFromCGRect(values_to_rect(values)) display:YES];
    },
    kPOPThresholdPoint
  },

  {kPOPWindowAlphaValue,
    ^(NSWindow *obj, CGFloat values[]) {
      values[0] = obj.alphaValue;
    },
    ^(NSWindow *obj, const CGFloat values[]) {
      obj.alphaValue = values[0];
    },
    kPOPThresholdOpacity
  },

  {kPOPWindowBackgroundColor,
    ^(NSWindow *obj, CGFloat values[]) {
      POPNSColorGetRGBAComponents(obj.backgroundColor, values);
    },
    ^(NSWindow *obj, const CGFloat values[]) {
      obj.backgroundColor = POPNSColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

#endif

#if SCENEKIT_SDK_AVAILABLE

  /* SceneKit */

  {kPOPSCNNodePosition,
    ^(SCNNode *obj, CGFloat values[]) {
      values_from_vec3(values, obj.position);
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.position = values_to_vec3(values);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodePositionX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.position.x;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.position = SCNVector3Make(values[0], obj.position.y, obj.position.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodePositionY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.position.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.position = SCNVector3Make(obj.position.x, values[0], obj.position.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodePositionZ,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.position.z;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.position = SCNVector3Make(obj.position.x, obj.position.y, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeTranslation,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.transform.m41;
      values[1] = obj.transform.m42;
      values[2] = obj.transform.m43;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.transform = SCNMatrix4MakeTranslation(values[0], values[1], values[2]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeTranslationX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.transform.m41;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.transform = SCNMatrix4MakeTranslation(values[0], obj.transform.m42, obj.transform.m43);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeTranslationY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.transform.m42;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.transform = SCNMatrix4MakeTranslation(obj.transform.m41, values[0], obj.transform.m43);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeTranslationY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.transform.m43;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.transform = SCNMatrix4MakeTranslation(obj.transform.m41, obj.transform.m42, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeRotation,
    ^(SCNNode *obj, CGFloat values[]) {
      values_from_vec4(values, obj.rotation);
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.rotation = values_to_vec4(values);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeRotationX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.rotation.x;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.rotation = SCNVector4Make(1.0, obj.rotation.y, obj.rotation.z, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeRotationY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.rotation.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.rotation = SCNVector4Make(obj.rotation.x, 1.0, obj.rotation.z, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeRotationZ,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.rotation.z;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.rotation = SCNVector4Make(obj.rotation.x, obj.rotation.y, 1.0, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeRotationW,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.rotation.w;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.rotation = SCNVector4Make(obj.rotation.x, obj.rotation.y, obj.rotation.z, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeEulerAngles,
    ^(SCNNode *obj, CGFloat values[]) {
      values_from_vec3(values, obj.eulerAngles);
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.eulerAngles = values_to_vec3(values);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeEulerAnglesX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.eulerAngles.x;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.eulerAngles = SCNVector3Make(values[0], obj.eulerAngles.y, obj.eulerAngles.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeEulerAnglesY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.eulerAngles.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.eulerAngles = SCNVector3Make(obj.eulerAngles.x, values[0], obj.eulerAngles.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeEulerAnglesZ,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.eulerAngles.z;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.eulerAngles = SCNVector3Make(obj.eulerAngles.x, obj.eulerAngles.y, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeOrientation,
    ^(SCNNode *obj, CGFloat values[]) {
      values_from_vec4(values, obj.orientation);
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.orientation = values_to_vec4(values);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeOrientationX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.orientation.x;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.orientation = SCNVector4Make(values[0], obj.orientation.y, obj.orientation.z, obj.orientation.w);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeOrientationY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.orientation.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.orientation = SCNVector4Make(obj.orientation.x, values[0], obj.orientation.z, obj.orientation.w);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeOrientationZ,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.orientation.z;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.orientation = SCNVector4Make(obj.orientation.x, obj.orientation.y, values[0], obj.orientation.w);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeOrientationW,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.orientation.w;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.orientation = SCNVector4Make(obj.orientation.x, obj.orientation.y, obj.orientation.z, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeScale,
    ^(SCNNode *obj, CGFloat values[]) {
      values_from_vec3(values, obj.scale);
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.scale = values_to_vec3(values);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeScaleX,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.scale.x;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.scale = SCNVector3Make(values[0], obj.scale.y, obj.scale.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeScaleY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.scale.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.position = SCNVector3Make(obj.scale.x, values[0], obj.scale.z);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeScaleZ,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.scale.z;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.scale = SCNVector3Make(obj.scale.x, obj.scale.y, values[0]);
    },
    kPOPThresholdScale
  },

  {kPOPSCNNodeScaleXY,
    ^(SCNNode *obj, CGFloat values[]) {
      values[0] = obj.scale.x;
      values[1] = obj.scale.y;
    },
    ^(SCNNode *obj, const CGFloat values[]) {
      obj.scale = SCNVector3Make(values[0], values[1], obj.scale.z);
    },
    kPOPThresholdScale
  },

#endif

};

static NSUInteger staticIndexWithName(NSString *aName)
{
  NSUInteger idx = 0;

  while (idx < POP_ARRAY_COUNT(_staticStates)) {
    if ([_staticStates[idx].name isEqualToString:aName])
      return idx;
    idx++;
  }

  return NSNotFound;
}

/**
 Concrete static property class.
 */
@interface POPStaticAnimatableProperty : POPAnimatableProperty
{
@public
  POPStaticAnimatablePropertyState *_state;
}
@end

@implementation POPStaticAnimatableProperty

- (NSString *)name
{
  return _state->name;
}

- (pop_animatable_read_block)readBlock
{
  return _state->readBlock;
}

- (pop_animatable_write_block)writeBlock
{
  return _state->writeBlock;
}

- (CGFloat)threshold
{
  return _state->threshold;
}

@end

#pragma mark - Concrete

/**
 Concrete immutable property class.
 */
@interface POPConcreteAnimatableProperty : POPAnimatableProperty
- (instancetype)initWithName:(NSString *)name readBlock:(pop_animatable_read_block)read writeBlock:(pop_animatable_write_block)write threshold:(CGFloat)threshold;
@end

@implementation POPConcreteAnimatableProperty

// default synthesis
@synthesize name, readBlock, writeBlock, threshold;

- (instancetype)initWithName:(NSString *)aName readBlock:(pop_animatable_read_block)aReadBlock writeBlock:(pop_animatable_write_block)aWriteBlock threshold:(CGFloat)aThreshold
{
  self = [super init];
  if (nil != self) {
    name = [aName copy];
    readBlock = [aReadBlock copy];
    writeBlock = [aWriteBlock copy];
    threshold = aThreshold;
  }
  return self;
}
@end

#pragma mark - Mutable

@implementation POPMutableAnimatableProperty

// default synthesis
@synthesize name, readBlock, writeBlock, threshold;

@end

#pragma mark - Cluster

/**
 Singleton placeholder property class to support class cluster.
 */
@interface POPPlaceholderAnimatableProperty : POPAnimatableProperty

@end

@implementation POPPlaceholderAnimatableProperty

// default synthesis
@synthesize name, readBlock, writeBlock, threshold;

@end

/**
 Cluster class.
 */
@implementation POPAnimatableProperty

// avoid creating backing ivars
@dynamic name, readBlock, writeBlock, threshold;

static POPAnimatableProperty *placeholder = nil;

+ (void)initialize
{
  if (self == [POPAnimatableProperty class]) {
    placeholder = [POPPlaceholderAnimatableProperty alloc];
  }
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
  if (self == [POPAnimatableProperty class]) {
    if (nil == placeholder) {
      placeholder = [super allocWithZone:zone];
    }
    return placeholder;
  }
  return [super allocWithZone:zone];
}

- (id)copyWithZone:(NSZone *)zone
{
  if ([self isKindOfClass:[POPMutableAnimatableProperty class]]) {
    POPConcreteAnimatableProperty *copyProperty = [[POPConcreteAnimatableProperty alloc] initWithName:self.name readBlock:self.readBlock writeBlock:self.writeBlock threshold:self.threshold];
    return copyProperty;
  } else {
    return self;
  }
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
  POPMutableAnimatableProperty *copyProperty = [[POPMutableAnimatableProperty alloc] init];
  copyProperty.name = self.name;
  copyProperty.readBlock = self.readBlock;
  copyProperty.writeBlock = self.writeBlock;
  copyProperty.threshold = self.threshold;
  return copyProperty;
}

+ (id)propertyWithName:(NSString *)aName
{
  return [self propertyWithName:aName initializer:NULL];
}

+ (id)propertyWithName:(NSString *)aName initializer:(void (^)(POPMutableAnimatableProperty *prop))aBlock
{
  POPAnimatableProperty *prop = nil;

  static NSMutableDictionary *_propertyDict = nil;
  if (nil == _propertyDict) {
    _propertyDict = [[NSMutableDictionary alloc] initWithCapacity:10];
  }

  prop = _propertyDict[aName];
  if (nil != prop) {
    return prop;
  }

  NSUInteger staticIdx = staticIndexWithName(aName);

  if (NSNotFound != staticIdx) {
    POPStaticAnimatableProperty *staticProp = [[POPStaticAnimatableProperty alloc] init];
    staticProp->_state = &_staticStates[staticIdx];
    _propertyDict[aName] = staticProp;
    prop = staticProp;
  } else if (NULL != aBlock) {
    POPMutableAnimatableProperty *mutableProp = [[POPMutableAnimatableProperty alloc] init];
    mutableProp.name = aName;
    mutableProp.threshold = 1.0;
    aBlock(mutableProp);
    prop = [mutableProp copy];
  }

  return prop;
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"%@ name:%@ threshold:%f", super.description, self.name, self.threshold];
  return s;
}

@end
