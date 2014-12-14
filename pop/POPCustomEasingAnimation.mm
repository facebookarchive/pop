#import "POPCustomEasingAnimationInternal.h"

////////////////////////////////////////////////////////////
// POPCustomEasingAnimation
@implementation POPCustomEasingAnimation

#undef __state
#define __state ((POPCustomEasingAnimationState *)_state)

#pragma mark - Lifecycle

- (void)_initState
{
  _state = new POPCustomEasingAnimationState(self);
}

+ (instancetype)animationWithEasingFunction:(CGFloat (^)(CGFloat t))easingFunction
{
  POPCustomEasingAnimation *anim = [self animation];
  anim.easingFunction = easingFunction;
  return anim;
}

#pragma mark - Properties
- (CGFloat (^)(CGFloat t))easingFunction
{
	return ((POPCustomEasingAnimationState *)_state)->easingFunction;
}

- (void)setEasingFunction:(CGFloat (^)(CGFloat t))value
{
  if (value == ((POPCustomEasingAnimationState *)_state)->easingFunction)
    return;

  ((POPCustomEasingAnimationState *)_state)->easingFunction = [value copy];
}

#pragma mark - Utility

- (void)_appendDescription:(NSMutableString *)s debug:(BOOL)debug
{
  [super _appendDescription:s debug:debug];
}

@end

////////////////////////////////////////////////////////////
// CAMediaTimingFunction (GoogleAnimationCurve)
@implementation CAMediaTimingFunction (GoogleAnimationCurve)
+ (CAMediaTimingFunction *)swiftOut
{
    return [CAMediaTimingFunction functionWithControlPoints:0.4 :0 :0.2 :1];
}
@end
