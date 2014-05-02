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

#pragma mark - Static

// CALayer
NSString * const kPOPLayerBackgroundColor = @"backgroundColor";
NSString * const kPOPLayerBounds = @"bounds";
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

// CAShapeLayer
NSString * const kPOPShapeLayerStrokeStart = @"shapeLayer.strokeStart";
NSString * const kPOPShapeLayerStrokeEnd = @"shapeLayer.strokeEnd";
NSString * const kPOPShapeLayerStrokeColor = @"shapeLayer.strokeColor";

// NSLayoutConstraint
NSString * const kPOPLayoutConstraintConstant = @"layoutConstraint.constant";

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

// UIScrollView
NSString * const kPOPScrollViewContentOffset = @"scrollView.contentOffset";
NSString * const kPOPScrollViewContentSize = @"scrollView.contentSize";

// UITableView
NSString * const kPOPTableViewContentOffset = kPOPScrollViewContentOffset;
NSString * const kPOPTableViewContentSize = kPOPScrollViewContentSize;

// UINavigationBar
NSString * const kPOPNavigationBarBarTintColor = @"navigationBar.barTintColor";

// UITabBar
NSString * const kPOPTabBarBarTintColor = kPOPNavigationBarBarTintColor;

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
  
  /* UIScrollView */
  
  {kPOPScrollViewContentOffset,
    ^(UIScrollView *obj, CGFloat values[]) {
      values_from_point(values, obj.contentOffset);
    },
    ^(UIScrollView *obj, const CGFloat values[]) {
      obj.contentOffset = values_to_point(values);
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
