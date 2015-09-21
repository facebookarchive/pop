//
//  POPGroupAnimationInternal.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-21.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPGroupAnimation.h"

@interface POPGroupAnimation ()

/**
 @abstract The array of keys for the animations running in this group.
 */
@property (nonatomic,copy,readonly) NSArray* animationKeys;

/**
 @abstract Adds an animations to this group. Group cannot be running.
 */
- (void)addAnimation:(POPAnimation*)animation;

@end
