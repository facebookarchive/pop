//
//  POPTransactionInternal.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPTransaction.h"
#import "POPAnimation.h"

@class POPPropertyAnimation;

@interface POPTransactionManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)canAddAnimationForObject:(id)obj;
- (void)addAnimation:(POPPropertyAnimation*)animation forObject:(id)obj;
- (POPPropertyAnimation*)animationForObject:(id)obj keyPath:(NSString*)keyPath;

@end

@interface POPTransaction ()

+ (void)setAnimationDelay:(CFTimeInterval)delay;
+ (CFTimeInterval)animationDelay;
+ (void)setAnimationOptions:(POPAnimationOptions)options;

+ (void)lock;
+ (void)unlock;

@end
