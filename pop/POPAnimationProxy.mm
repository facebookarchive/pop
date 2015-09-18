//
//  POPAnimationProxy.m
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPAnimationProxy.h"
#import "POPAnimatablePropertyInternal.h"
#import "POPBasicAnimation.h"
#import "POPAnimatorPrivate.h"
#import "POPTransactionInternal.h"

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

- (id)_argumentValueFromInvocation:(NSInvocation*)invocation atIndex:(NSUInteger)index forValueType:(POPValueType)type
{
  switch (type) {
    case kPOPValueInteger:
      NSInteger itg;
      [invocation getArgument:&itg atIndex:index];
      return @(itg);
      break;
    case kPOPValueFloat:
      CGFloat flt;
      [invocation getArgument:&flt atIndex:index];
      return @(flt);
      break;
    case kPOPValuePoint:
      CGPoint point;
      [invocation getArgument:&point atIndex:index];
      return [NSValue valueWithCGPoint:point];
      break;
    case kPOPValueSize:
      CGSize size;
      [invocation getArgument:&size atIndex:index];
      return [NSValue valueWithCGSize:size];
      break;
    case kPOPValueRect:
      CGRect rect;
      [invocation getArgument:&rect atIndex:index];
      return [NSValue valueWithCGRect:rect];
      break;
#if TARGET_OS_IPHONE
    case kPOPValueEdgeInsets:
      UIEdgeInsets insets;
      [invocation getArgument:&insets atIndex:index];
      return [NSValue valueWithUIEdgeInsets:insets];
      break;
#endif
    case kPOPValueColor: {
      CGColorRef color;
      [invocation getArgument:&color atIndex:index];
      return (__bridge_transfer id)color;
      break;
    }
#if SCENEKIT_SDK_AVAILABLE
    case kPOPValueSCNVector3: {
      SCNVector3 scnVec3;
      [invocation getArgument:&scnVec3 atIndex:index];
      return [NSValue valueWithSCNVector3:scnVec3];
      break;
    }
    case kPOPValueSCNVector4: {
      SCNVector4 scnVec4;
      [invocation getArgument:&scnVec4 atIndex:index];
      return [NSValue valueWithSCNVector3:scnVec4];
      break;
    }
#endif
    case kPOPValueGLKVector3: {
      GLKVector3 glkVec3;
      [invocation getArgument:&glkVec3 atIndex:index];
      return [NSValue valueWithGLKVector3:glkVec3];
      break;
    }
      
    case kPOPValueGLKQuaternion: {
      GLKVector3 glkVec3;
      [invocation getArgument:&glkVec3 atIndex:index];
      return [NSValue valueWithGLKVector3:glkVec3];
      break;
    }
    default:
      break;
  }
  
  return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  if ( [[POPTransactionManager sharedManager] canAddAnimationForObject:self.object] && ![POPTransaction disableActions] )
  {
    // on forward, we get the selector from the invocation nad figure out what it is that is being animated
    // if we find it, we find/add/update an animation for it
    NSString* methodName = NSStringFromSelector(invocation.selector);
    NSMethodSignature* signature = [invocation methodSignature];
    if ( signature.numberOfArguments == 3 && methodName.length > 3 && [methodName hasPrefix:@"set"] )
    {
      // get the value type that is being set
      const char* type = [signature getArgumentTypeAtIndex:2];
      POPValueType valueType = POPSelectValueType(type, kPOPAnimatableSupportTypes, POP_ARRAY_COUNT(kPOPAnimatableSupportTypes));
      id value = [self _argumentValueFromInvocation:invocation atIndex:2 forValueType:valueType];
      if ( value ) {
        // get the property name without the leading 'set' and the trailling ':'
        NSString* propertyName = [methodName substringWithRange:NSMakeRange(3, methodName.length-4)];
        propertyName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[propertyName substringWithRange:NSMakeRange(0, 1)] lowercaseString]];
        
        POPAnimatableProperty* property = nil;
        // check for a custom property
        property = [[POPAnimator sharedAnimator] customAnimatablePropertyForObject:self.object keyPath:propertyName];
        if ( !property ) {
          // try and get a built in property
          property = [POPAnimatableProperty propertyWithName:[NSString stringWithFormat:@"%p:%@", self.object, propertyName] keyPath:propertyName valueType:valueType];
        }
        
        // execute it if it exists
        if ( property )
        {
          POPBasicAnimation* anim = [POPBasicAnimation animationWithKeyPath:propertyName];
          anim.toValue = value;
          [[POPTransactionManager sharedManager] addAnimation:anim forObject:self.object];
          return;
        }
      }
    }
  }
  
  // we couldn't figure out how to create an animation for this, we just pass on the message
  [invocation invokeWithTarget:self.object];
}

@end
