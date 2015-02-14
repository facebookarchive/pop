/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCTest/XCTest.h>

#import <pop/POPAnimatableProperty.h>

static const CGFloat epsilon = 0.0001f;
static NSArray *properties = @[@"name", @"readBlock", @"writeBlock", @"threshold"];

static void assertPropertyEqual(id self, POPAnimatableProperty *prop1, POPAnimatableProperty *prop2)
{
  for (NSString *property in properties) {
    id value = [prop1 valueForKey:property];
    id valueCopy = [prop2 valueForKey:property];
    XCTAssertEqualObjects(value, valueCopy, @"unexpected inequality; value:%@ copy:%@", value, valueCopy);
  }
}

@interface POPAnimatablePropertyTests : XCTestCase
@end

@implementation POPAnimatablePropertyTests

- (void)testProvidedExistence
{
  NSArray *names = @[kPOPLayerPosition,
                     kPOPLayerOpacity,
                     kPOPLayerScaleXY,
                     kPOPLayerSubscaleXY,
                     kPOPLayerSubtranslationX,
                     kPOPLayerSubtranslationY,
                     kPOPLayerSubtranslationZ,
                     kPOPLayerSubtranslationXY,
                     kPOPLayerZPosition,
                     kPOPLayerSize,
                     kPOPLayerRotation,
                     kPOPLayerRotationY,
                     kPOPLayerRotationX,
                     kPOPLayerShadowColor,
                     kPOPLayerShadowOffset,
                     kPOPLayerShadowOpacity,
                     kPOPLayerShadowRadius,
                     kPOPLayerCornerRadius,
                     kPOPLayerBorderWidth,
                     kPOPLayerBorderColor,
                     kPOPShapeLayerStrokeStart,
                     kPOPShapeLayerStrokeEnd,
                     kPOPShapeLayerStrokeColor,
                     kPOPShapeLayerLineWidth,
#if TARGET_OS_IPHONE
                     kPOPViewAlpha,
                     kPOPViewBackgroundColor,
                     kPOPViewCenter,
                     kPOPViewFrame,
                     kPOPViewBounds,
                     kPOPViewSize,
                     kPOPViewTintColor,
                     kPOPScrollViewZoomScale,
                     kPOPTableViewContentSize,
                     kPOPTableViewContentOffset,
                     kPOPCollectionViewContentSize,
                     kPOPCollectionViewContentSize,
                     kPOPLabelTextColor
#else
                     kPOPViewFrame,
                     kPOPViewBounds,
                     kPOPViewAlphaValue,
                     kPOPViewFrameRotation,
                     kPOPViewFrameCenterRotation,
                     kPOPViewBoundsRotation,
                     kPOPWindowFrame,
                     kPOPWindowAlphaValue,
                     kPOPWindowBackgroundColor
#endif
                     ];

  for (NSString *name in names) {
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:name];
    XCTAssertNotNil(prop, @"animatable property %@ should exist", name);
  }
}

- (void)testUserCreation
{
  static NSString *name = @"lalalala";
  static CGFloat threshold = 0.07;
  POPAnimatableProperty *prop;

  prop = [POPAnimatableProperty propertyWithName:name];
  XCTAssertNil(prop, @"animatable property %@ should not exist", name);

  prop = [POPAnimatableProperty propertyWithName:name initializer:^(POPMutableAnimatableProperty *p){
    p.threshold = threshold;
  }];
  XCTAssertNotNil(prop, @"animatable property %@ should exist", name);
  XCTAssertEqualWithAccuracy(threshold, prop.threshold, epsilon, @"property threshold %f should equal %f", prop.threshold, threshold);
}

- (void)testClassCluster
{
  POPAnimatableProperty *instance1 = [[POPAnimatableProperty alloc] init];
  POPAnimatableProperty *instance2 = [[POPAnimatableProperty alloc] init];
  XCTAssertTrue(instance1 == instance2, @"instance1:%@ instance2:%@", instance1, instance2);

  for (NSString *property in properties) {
    XCTAssertNoThrow([instance1 valueForKey:property], @"exception on %@", property);
  }
}

- (void)testCopying
{
  // instance
  POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];

  // instance copy
  POPAnimatableProperty *propCopy = [prop copy];

  // test equality
  assertPropertyEqual(self, prop, propCopy);
}

- (void)testMutableCopying
{
  // instance
  POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:kPOPLayerBounds];

  // instance copy
  POPAnimatableProperty *propCopy = [prop mutableCopy];

  // test equality
  assertPropertyEqual(self, prop, propCopy);
}

@end
