/**
  Copyright (c) 2014-present, Facebook, Inc.
  All rights reserved.

  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimatableProperty.h"
#import "POPCGUtils.h"
#import "POPAnimationRuntime.h"

#import <QuartzCore/QuartzCore.h>

#import <POP/POPLayerExtras.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/NSLayoutConstraint.h>
#endif

// common threshold definitions
static CGFloat const kPOPThresholdColor = 0.01;
static CGFloat const kPOPThresholdPoint = 1.0;
static CGFloat const kPOPThresholdOpacity = 0.01;
static CGFloat const kPOPThresholdScale = 0.005;
static CGFloat const kPOPThresholdRotation = 0.01;
static CGFloat const kPOPThresholdRadius = 0.01;

/**
 State structure internal to static animatable property.
 */
typedef struct
{
  POPAnimatablePropertyType type;
  pop_animatable_read_block readBlock;
  pop_animatable_write_block writeBlock;
  CGFloat threshold;
} _POPStaticAnimatablePropertyState;
typedef _POPStaticAnimatablePropertyState POPStaticAnimatablePropertyState;

static POPStaticAnimatablePropertyState _staticStates[] =
{
  /* CALayer */

  {POPLayerBackgroundColor,
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

  {POPLayerBounds,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_rect(values, [obj bounds]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setBounds:values_to_rect(values)];
    },
    kPOPThresholdPoint
  },

  {POPLayerCornerRadius,
    ^(CALayer *obj, CGFloat values[]) {
        values[0] = [obj cornerRadius];
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setCornerRadius:values[0]];
    },
    kPOPThresholdRadius
  },

  {POPLayerPosition,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, [(CALayer *)obj position]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setPosition:values_to_point(values)];
    },
    kPOPThresholdPoint
  },

  {POPLayerPositionX,
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

  {POPLayerPositionY,
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

  {POPLayerOpacity,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj opacity];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setOpacity:((float)values[0])];
    },
    kPOPThresholdOpacity
  },

  {POPLayerScaleX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleX(obj, values[0]);
    },
    kPOPThresholdScale
  },

  {POPLayerScaleY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleY(obj, values[0]);
    },
    kPOPThresholdScale
  },

  {POPLayerScaleXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetScaleXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetScaleXY(obj, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {POPLayerSubscaleXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetSubScaleXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubScaleXY(obj, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {POPLayerTranslationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationX(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerTranslationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationY(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerTranslationZ,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetTranslationZ(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationZ(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerTranslationXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetTranslationXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetTranslationXY(obj, values_to_point(values));
    },
    kPOPThresholdPoint
  },

  {POPLayerSubtranslationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationX(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerSubtranslationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationY(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationY(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerSubtranslationZ,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetSubTranslationZ(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationZ(obj, values[0]);
    },
    kPOPThresholdPoint
  },

  {POPLayerSubtranslationXY,
    ^(CALayer *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetSubTranslationXY(obj));
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetSubTranslationXY(obj, values_to_point(values));
    },
    kPOPThresholdPoint
  },

  {POPLayerZPosition,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = [obj zPosition];
    },
    ^(CALayer *obj, const CGFloat values[]) {
      [obj setZPosition:values[0]];
    },
    kPOPThresholdPoint
  },

  {POPLayerSize,
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

  {POPLayerRotation,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotation(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetRotation(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {POPLayerRotationY,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotationY(obj);
    },
    ^(id obj, const CGFloat values[]) {
      POPLayerSetRotationY(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {POPLayerRotationX,
    ^(CALayer *obj, CGFloat values[]) {
      values[0] = POPLayerGetRotationX(obj);
    },
    ^(CALayer *obj, const CGFloat values[]) {
      POPLayerSetRotationX(obj, values[0]);
    },
    kPOPThresholdRotation
  },

  {POPLayerShadowColor,
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

  {POPLayerShadowOffset,
    ^(CALayer *obj, CGFloat values[]) {
        values_from_size(values, [obj shadowOffset]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
        CGSize size = values_to_size(values);
        [obj setShadowOffset:size];
    },
    0.01
  },

  {POPLayerShadowOpacity,
    ^(CALayer *obj, CGFloat values[]) {
        values[0] = [obj shadowOpacity];
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setShadowOpacity:values[0]];
    },
    0.01
  },

  {POPLayerShadowRadius,
    ^(CALayer *obj, CGFloat values[]) {
        values[0] = [obj shadowRadius];
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setShadowRadius:values[0]];
    },
    kPOPThresholdRadius
  },

  /* CAShapeLayer */

  {POPShapeLayerStrokeStart,
    ^(CAShapeLayer *obj, CGFloat values[]) {
      values[0] = obj.strokeStart;
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
      obj.strokeStart = values[0];
    },
    0.01
  },

  {POPShapeLayerStrokeEnd,
    ^(CAShapeLayer *obj, CGFloat values[]) {
      values[0] = obj.strokeEnd;
    },
    ^(CAShapeLayer *obj, const CGFloat values[]) {
      obj.strokeEnd = values[0];
    },
    0.01
  },

  {POPShapeLayerStrokeColor,
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

  {POPLayoutConstraintConstant,
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

  {POPViewAlpha,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = obj.alpha;
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.alpha = values[0];
    },
    kPOPThresholdOpacity
  },

  {POPViewBackgroundColor,
    ^(UIView *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.backgroundColor, values);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.backgroundColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },
    
  {POPViewBounds,
    ^(CALayer *obj, CGFloat values[]) {
        values_from_rect(values, [obj bounds]);
    },
    ^(CALayer *obj, const CGFloat values[]) {
        [obj setBounds:values_to_rect(values)];
    },
    kPOPThresholdPoint
  },

  {POPViewCenter,
    ^(UIView *obj, CGFloat values[]) {
      values_from_point(values, obj.center);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.center = values_to_point(values);
    },
    kPOPThresholdPoint
  },

  {POPViewFrame,
    ^(UIView *obj, CGFloat values[]) {
      values_from_rect(values, obj.frame);
    },
    ^(UIView *obj, const CGFloat values[]) {
      obj.frame = values_to_rect(values);
    },
    kPOPThresholdPoint
  },

  {POPViewScaleX,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleX(obj.layer);
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleX(obj.layer, values[0]);
    },
    kPOPThresholdScale
  },

  {POPViewScaleY,
    ^(UIView *obj, CGFloat values[]) {
      values[0] = POPLayerGetScaleY(obj.layer);
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleY(obj.layer, values[0]);
    },
    kPOPThresholdScale
  },

  {POPViewScaleXY,
    ^(UIView *obj, CGFloat values[]) {
      values_from_point(values, POPLayerGetScaleXY(obj.layer));
    },
    ^(UIView *obj, const CGFloat values[]) {
      POPLayerSetScaleXY(obj.layer, values_to_point(values));
    },
    kPOPThresholdScale
  },

  {POPViewSize,
    ^(UIView *obj, CGFloat values[]) {
        values_from_size(values, [obj bounds].size);
    },
    ^(UIView *obj, const CGFloat values[]) {
        CGSize size = values_to_size(values);
        if (size.width < 0. || size.height < 0.)
            return;
            
        CGRect b = [obj bounds];
        b.size = size;
        [obj setBounds:b];
    },
    kPOPThresholdPoint
  },
    
  /* UIScrollView */

  {POPScrollViewContentOffset,
    ^(UIScrollView *obj, CGFloat values[]) {
      values_from_point(values, obj.contentOffset);
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.contentOffset = values_to_point(values);
    },
    kPOPThresholdPoint
  },

  {POPScrollViewContentSize,
    ^(UIScrollView *obj, CGFloat values[]) {
      values_from_size(values, obj.contentSize);
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.contentSize = values_to_size(values);
    },
    kPOPThresholdPoint
  },
    
  {POPScrollViewZoomScale,
    ^(UIScrollView *obj, CGFloat values[]) {
      values[0]=obj.zoomScale;
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.zoomScale=values[0];
    },
    kPOPThresholdScale
  },

  /* UINavigationBar */

  {POPNavigationBarBarTintColor,
    ^(UINavigationBar *obj, CGFloat values[]) { 
      POPUIColorGetRGBAComponents(obj.barTintColor, values);
    },
    ^(UINavigationBar *obj, const CGFloat values[]) {
      obj.barTintColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

  /* UILabel */

  {POPLabelTextColor,
    ^(UILabel *obj, CGFloat values[]) {
      POPUIColorGetRGBAComponents(obj.textColor, values);
    },
    ^(UILabel *obj, const CGFloat values[]) {
      obj.textColor = POPUIColorRGBACreate(values);
    },
    kPOPThresholdColor
  },

    /* UITableView */

  {POPTableViewContentSize,
    ^(UITableView *obj, CGFloat values[]) {
        values_from_size(values, obj.contentSize);
    },
    ^(UITableView *obj, const CGFloat values[]) {
        obj.contentSize = values_to_size(values);
    },
    kPOPThresholdPoint
  },
    
  {POPTableViewContentOffset,
    ^(UITableView *obj, CGFloat values[]) {
        values_from_point(values, obj.contentOffset);
    },
    ^(UITableView *obj, const CGFloat values[]) {
        obj.contentOffset = values_to_point(values);
    },
    kPOPThresholdPoint
  },
#endif

};

static NSUInteger staticIndexWithType(POPAnimatablePropertyType type)
{
  NSUInteger idx = 0;

  while (idx < POP_ARRAY_COUNT(_staticStates)) {
    if (_staticStates[idx].type == type)
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

- (POPAnimatablePropertyType)type
{
  return _state->type;
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
- (instancetype)initWithType:(POPAnimatablePropertyType)type readBlock:(pop_animatable_read_block)read writeBlock:(pop_animatable_write_block)write threshold:(CGFloat)threshold;
@end

@implementation POPConcreteAnimatableProperty

// default synthesis
@synthesize type, readBlock, writeBlock, threshold;

- (instancetype)initWithType:(POPAnimatablePropertyType)aType readBlock:(pop_animatable_read_block)aReadBlock writeBlock:(pop_animatable_write_block)aWriteBlock threshold:(CGFloat)aThreshold
{
  self = [super init];
  if (nil != self) {
    type = aType;
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
@synthesize type, readBlock, writeBlock, threshold;

@end

#pragma mark - Cluster

/**
 Singleton placeholder property class to support class cluster.
 */
@interface POPPlaceholderAnimatableProperty : POPAnimatableProperty

@end

@implementation POPPlaceholderAnimatableProperty

// default synthesis
@synthesize type, readBlock, writeBlock, threshold;

@end

/**
 Cluster class.
 */
@implementation POPAnimatableProperty

// avoid creating backing ivars
@dynamic type, readBlock, writeBlock, threshold;

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
    POPConcreteAnimatableProperty *copyProperty = [[POPConcreteAnimatableProperty alloc] initWithType:self.type readBlock:self.readBlock writeBlock:self.writeBlock threshold:self.threshold];
    return copyProperty;
  } else {
    return self;
  }
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
  POPMutableAnimatableProperty *copyProperty = [[POPMutableAnimatableProperty alloc] init];
  copyProperty.type = self.type;
  copyProperty.readBlock = self.readBlock;
  copyProperty.writeBlock = self.writeBlock;
  copyProperty.threshold = self.threshold;
  return copyProperty;
}

+ (id)propertyWithType:(POPAnimatablePropertyType)aType
{
  return [self propertyWithType:aType initializer:NULL];
}

+ (id)propertyWithCustomProperty:(NSString *)customProperty
{
  return [self propertyWithCustomProperty:customProperty initializer:NULL];
}

+ (id)propertyWithType:(POPAnimatablePropertyType)aType initializer:(void (^)(POPMutableAnimatableProperty *prop))aBlock
{
  POPAnimatableProperty *prop = nil;

  static NSMutableDictionary *_propertyDict = nil;
  if (nil == _propertyDict) {
    _propertyDict = [[NSMutableDictionary alloc] initWithCapacity:10];
  }

  prop = _propertyDict[@(aType)];
  if (nil != prop) {
    return prop;
  }

  NSUInteger staticIdx = staticIndexWithType(aType);

  if (NSNotFound != staticIdx) {
    POPStaticAnimatableProperty *staticProp = [[POPStaticAnimatableProperty alloc] init];
    staticProp->_state = &_staticStates[staticIdx];
    _propertyDict[@(aType)] = staticProp;
    prop = staticProp;
  } else if (NULL != aBlock) {
    POPMutableAnimatableProperty *mutableProp = [[POPMutableAnimatableProperty alloc] init];
    mutableProp.type = aType;
    mutableProp.threshold = 1.0;
    aBlock(mutableProp);
    prop = [mutableProp copy];
  }

  return prop;
}

+ (id)propertyWithCustomProperty:(NSString *)customProperty initializer:(void (^)(POPMutableAnimatableProperty *prop))aBlock
{
    POPAnimatableProperty *prop = nil;
    
    static NSMutableDictionary *_propertyDict = nil;
    if (nil == _propertyDict) {
        _propertyDict = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    
    prop = _propertyDict[customProperty];
    if (nil != prop) {
        return prop;
    }
    
    if (NULL != aBlock) {
        POPMutableAnimatableProperty *mutableProp = [[POPMutableAnimatableProperty alloc] init];
        mutableProp.type = POPCustomProperty;
        mutableProp.threshold = 1.0;
        aBlock(mutableProp);
        prop = [mutableProp copy];
    }
    
    return prop;
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"%@ type:%d threshold:%f", super.description, self.type, self.threshold];
  return s;
}

@end
