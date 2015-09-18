//
//  POPTransactionInternal.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPTransaction.h"

@class POPBasicAnimation;

@interface POPTransactionManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)canAddAnimationForObject:(id)obj;
- (void)addAnimation:(POPBasicAnimation*)animation forObject:(id)obj;

@end

