/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#if SCENEKIT_SDK_AVAILABLE
#import <SceneKit/SceneKit.h>
#endif

#import "POPDefines.h"

POP_EXTERN_C_BEGIN

NS_INLINE CGPoint values_to_point(const CGFloat values[])
{
  return CGPointMake(values[0], values[1]);
}

NS_INLINE CGSize values_to_size(const CGFloat values[])
{
  return CGSizeMake(values[0], values[1]);
}

NS_INLINE CGRect values_to_rect(const CGFloat values[])
{
  return CGRectMake(values[0], values[1], values[2], values[3]);
}

#if SCENEKIT_SDK_AVAILABLE
NS_INLINE SCNVector3 values_to_vec3(const CGFloat values[])
{
  return SCNVector3Make(values[0], values[1], values[2]);
}

NS_INLINE SCNVector4 values_to_vec4(const CGFloat values[])
{
  return SCNVector4Make(values[0], values[1], values[2], values[3]);
}
#endif

#if TARGET_OS_IPHONE

NS_INLINE UIEdgeInsets values_to_edge_insets(const CGFloat values[])
{
  return UIEdgeInsetsMake(values[0], values[1], values[2], values[3]);
}

#endif

NS_INLINE void values_from_point(CGFloat values[], CGPoint p)
{
  values[0] = p.x;
  values[1] = p.y;
}

NS_INLINE void values_from_size(CGFloat values[], CGSize s)
{
  values[0] = s.width;
  values[1] = s.height;
}

NS_INLINE void values_from_rect(CGFloat values[], CGRect r)
{
  values[0] = r.origin.x;
  values[1] = r.origin.y;
  values[2] = r.size.width;
  values[3] = r.size.height;
}

#if SCENEKIT_SDK_AVAILABLE
NS_INLINE void values_from_vec3(CGFloat values[], SCNVector3 v)
{
  values[0] = v.x;
  values[1] = v.y;
  values[2] = v.z;
}

NS_INLINE void values_from_vec4(CGFloat values[], SCNVector4 v)
{
  values[0] = v.x;
  values[1] = v.y;
  values[2] = v.z;
  values[3] = v.w;
}
#endif

#if TARGET_OS_IPHONE

NS_INLINE void values_from_edge_insets(CGFloat values[], UIEdgeInsets i)
{
  values[0] = i.top;
  values[1] = i.left;
  values[2] = i.bottom;
  values[3] = i.right;
}

#endif

/**
 Takes a CGColorRef and converts it into RGBA components, if necessary.
 */
extern void POPCGColorGetRGBAComponents(CGColorRef color, CGFloat components[]);

/**
 Takes RGBA components and returns a CGColorRef.
 */
extern CGColorRef POPCGColorRGBACreate(const CGFloat components[]) CF_RETURNS_RETAINED;

/**
 Takes a color reference and returns a CGColor.
 */
extern CGColorRef POPCGColorWithColor(id color);

#if TARGET_OS_IPHONE

/**
 Takes a UIColor and converts it into RGBA components, if necessary.
 */
extern void POPUIColorGetRGBAComponents(UIColor *color, CGFloat components[]);

/**
 Takes RGBA components and returns a UIColor.
 */
extern UIColor *POPUIColorRGBACreate(const CGFloat components[]) NS_RETURNS_RETAINED;

#else

/**
 Takes a NSColor and converts it into RGBA components, if necessary.
 */
extern void POPNSColorGetRGBAComponents(NSColor *color, CGFloat components[]);

/**
 Takes RGBA components and returns a NSColor.
 */
extern NSColor *POPNSColorRGBACreate(const CGFloat components[]) NS_RETURNS_RETAINED;

#endif

POP_EXTERN_C_END
