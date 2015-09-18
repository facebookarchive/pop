//
//  POPAnimationProxy.h
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface POPAnimationProxy : NSProxy

- (instancetype)initWithObject:(id)object;

@property (weak,readonly) id object;

@end
