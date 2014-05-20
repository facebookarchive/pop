//
//  POPAnimatablePropertyTypes.h
//  pop
//
//  Created by Jerome Morissard on 5/19/14.
//  Copyright (c) 2014 Facebook. All rights reserved.
//

#ifndef pop_POPAnimatablePropertyTypes_h
#define pop_POPAnimatablePropertyTypes_h

typedef NS_ENUM(NSUInteger, POPAnimatablePropertyType) {
    /**
     Common CALayer property names.
     */
    
    POPLayerBackgroundColor = 0,
    POPLayerBounds,
    POPLayerCornerRadius,
    POPLayerOpacity,
    POPLayerPosition,
    POPLayerPositionX,
    POPLayerPositionY,
    POPLayerRotation,
    POPLayerRotationX,
    POPLayerRotationY,
    POPLayerScaleX,
    POPLayerScaleXY,
    POPLayerScaleY,
    POPLayerSize,
    POPLayerSubscaleXY,
    POPLayerSubtranslationX,
    POPLayerSubtranslationXY,
    POPLayerSubtranslationY,
    POPLayerSubtranslationZ,
    POPLayerTranslationX,
    POPLayerTranslationXY,
    POPLayerTranslationY,
    POPLayerTranslationZ,
    POPLayerZPosition,
    POPLayerShadowColor,
    POPLayerShadowOffset,
    POPLayerShadowOpacity,
    POPLayerShadowRadius,
    /**
     Common CAShapeLayer property names.
     */
    POPShapeLayerStrokeStart = 100,
    POPShapeLayerStrokeEnd,
    POPShapeLayerStrokeColor,
    
#if TARGET_OS_IPHONE
    
    /**
     Common UIView property names.
     */
    POPViewAlpha = 200,
    POPViewBackgroundColor,
    POPViewBounds,
    POPViewCenter,
    POPViewFrame,
    POPViewScaleX,
    POPViewScaleXY,
    POPViewScaleY,
    POPViewSize,
    
    /**
     Common UIScrollView property names.
     */
    POPScrollViewContentOffset = 300,
    POPScrollViewContentSize,
    POPScrollViewZoomScale,
    
    /**
     Common UITableView property names.
     */
    POPTableViewContentOffset = 400,
    POPTableViewContentSize,
    
    /**
     Common UINavigationBar property names.
     */
    POPNavigationBarBarTintColor = 500,
    
    /**
     Common UIToolbar property names.
     */
    POPToolbarBarTintColor = 600,
    
    /**
     Common UITabBar property names.
     */
    POPTabBarBarTintColor = 700,
    
    /**
     Common UILabel property names.
     */
    POPLabelTextColor = 800,
    
#endif
    
    /**
     Common NSLayoutConstraint property names.
     */
    POPLayoutConstraintConstant = 10000
};


#endif
