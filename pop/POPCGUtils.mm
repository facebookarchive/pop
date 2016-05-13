/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPCGUtils.h"

#import <objc/runtime.h>

void POPCGColorGetRGBAComponents(CGColorRef color, CGFloat components[])
{
  if (color) {
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
  } else {
    memset(components, 0, 4 * sizeof(components[0]));
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
    // -[NSColor CGColor] is only supported since OSX 10.8+
    if ([color respondsToSelector:@selector(CGColor)]) {
      return [color CGColor];
    }

    /*
     * Otherwise create a CGColorRef manually.
     *
     * The original accessor is (or would be) declared as:
     *   @property(readonly) CGColorRef CGColor;
     *   - (CGColorRef)CGColor NS_RETURNS_INNER_POINTER CF_RETURNS_NOT_RETAINED;
     *
     * (Please note that OSX' accessor is atomic, while iOS' isn't.)
     *
     * The access to the NSColor object must thus be synchronized
     * and the CGColorRef be stored as an associated object,
     * to return a reference which doesn't need to be released manually.
     */
    @synchronized(color) {
      static const void* key = &key;

      CGColorRef colorRef = (__bridge CGColorRef)objc_getAssociatedObject(color, key);

      if (!colorRef) {
        size_t numberOfComponents = [(NSColor *)color numberOfComponents];
        CGFloat components[numberOfComponents];
        CGColorSpaceRef colorSpace = [[(NSColor *)color colorSpace] CGColorSpace];

        [color getComponents:components];

        colorRef = CGColorCreate(colorSpace, components);

        objc_setAssociatedObject(color, key, (__bridge id)colorRef, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CGColorRelease(colorRef);
      }

      return colorRef;
    }
  }
#endif
  return nil;
}

#if TARGET_OS_IPHONE

void POPUIColorGetRGBAComponents(UIColor *color, CGFloat components[])
{
  return POPCGColorGetRGBAComponents(POPCGColorWithColor(color), components);
}

UIColor *POPUIColorRGBACreate(const CGFloat components[])
{
  CGColorRef colorRef = POPCGColorRGBACreate(components);
  UIColor *color = [[UIColor alloc] initWithCGColor:colorRef];
  CGColorRelease(colorRef);
  return color;
}

#else

void POPNSColorGetRGBAComponents(NSColor *color, CGFloat components[])
{
  return POPCGColorGetRGBAComponents(POPCGColorWithColor(color), components);
}

NSColor *POPNSColorRGBACreate(const CGFloat components[])
{
  CGColorRef colorRef = POPCGColorRGBACreate(components);
  NSColor *color = nil;

  if (colorRef) {
    if ([NSColor respondsToSelector:@selector(colorWithCGColor:)]) {
      color = [NSColor colorWithCGColor:colorRef];
    } else {
      color = [NSColor colorWithCIColor:[CIColor colorWithCGColor:colorRef]];
    }

    CGColorRelease(colorRef);
  }

  return color;
}

#endif

