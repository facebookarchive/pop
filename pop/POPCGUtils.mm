/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPCGUtils.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIColor.h>
#else
#import <AppKit/NSColor.h>
#endif

void POPCGColorGetRGBAComponents(CGColorRef color, CGFloat components[])
{
  if (!color) {
#if TARGET_OS_IPHONE
    color = [UIColor clearColor].CGColor;
#else
    color = [NSColor clearColor].CGColor;
#endif
  }
  
  const CGFloat *colors = CGColorGetComponents(color);
  size_t count = CGColorGetNumberOfComponents(color);
  
  if (4 == count) {
    // RGB colorspace
    components[0] = colors[0];
    components[1] = colors[1];
    components[2] = colors[2];
    components[3] = colors[3];
  } else if (2 == count) {
    // Grey colorspace
    components[0] = components[1] = components[2] = colors[0];
    components[3] = colors[1];
  } else {
    // Use CI to convert
    CIColor *ciColor = [CIColor colorWithCGColor:color];
    components[0] = ciColor.red;
    components[1] = ciColor.green;
    components[2] = ciColor.blue;
    components[3] = ciColor.alpha;
  }
}

CGColorRef POPCGColorRGBACreate(const CGFloat components[])
{
#if TARGET_OS_IPHONE
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  CGColorRef color = CGColorCreate(space, components);
  CGColorSpaceRelease(space);
  return color;
#else
  return CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
#endif
}

CGColorRef POPCGColorWithColor(id color)
{
  if (CFGetTypeID((__bridge CFTypeRef)color) == CGColorGetTypeID()) {
    return ((__bridge CGColorRef)color);
  }
#if TARGET_OS_IPHONE
  else if ([color isKindOfClass:[UIColor class]]) {
    return [color CGColor];
  }
#else
  else if ([color isKindOfClass:[NSColor class]]) {
    return [color CGColor];
  }
#endif
  return nil;
}

#if TARGET_OS_IPHONE

void POPUIColorGetRGBAComponents(UIColor *color, CGFloat components[])
{
  return POPCGColorGetRGBAComponents(color.CGColor, components);
}

UIColor *POPUIColorRGBACreate(const CGFloat components[])
{
  CGColorRef colorRef = POPCGColorRGBACreate(components);
  UIColor *color = [[UIColor alloc] initWithCGColor:colorRef];
  CGColorRelease(colorRef);
  return color;
}

#endif

