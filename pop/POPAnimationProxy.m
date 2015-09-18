//
//  POPAnimationProxy.m
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPAnimationProxy.h"

@interface POPAnimationProxy ()

@property (weak) id object;

@end

@implementation POPAnimationProxy

@synthesize object;

- (instancetype)initWithObject:(id)obj
{
  self.object = obj;
  return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  return [self.object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  // on forward, we get the selector from the invocation nad figure out what it is that is being animated
  // if we find it, we find/add/update an animation for it
  NSString* methodName = NSStringFromSelector(invocation.selector);
  if ( methodName.length > 3 && [methodName hasPrefix:@"set"] )
  {
    NSString* propertyName = [methodName substringFromIndex:3];
    propertyName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
    
    // find a property for it
    
  }

  [invocation invokeWithTarget:self.object];
}

@end
