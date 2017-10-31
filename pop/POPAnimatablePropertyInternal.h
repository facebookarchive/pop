/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimatableProperty.h"

@interface POPAnimatableProperty ()

/**
 @abstract Property accessor.
 @param name The name of the property.
 @param keyPath The keyPath of the property.
 @param valueType The type of objC value of the property.
 @return The animatable property for that keyPath or nil if it can't be created.
 @discussion Used by animations created with keyPaths.
 */
+ (id)propertyWithName:(NSString*)name keyPath:(NSString*)keyPath valueType:(POPValueType)valueType;

@end
