#import "POPCustomEasingAnimation.h"
#import "POPBasicAnimationInternal.h"
#import "POPPropertyAnimationInternal.h"

struct _POPCustomEasingAnimationState : _POPBasicAnimationState
{
	CGFloat (^easingFunction)(CGFloat t);
	
	_POPCustomEasingAnimationState(id __unsafe_unretained anim) : _POPBasicAnimationState(anim),
		easingFunction(nil)
	{
	}

	bool advance(CFTimeInterval time, CFTimeInterval dt, id obj)
	{
		if(easingFunction)
		{
			// cap local time to duration
			CGFloat localTime = time - startTime;

			// solve for normalized time, aka progresss [0, 1]
			if (duration > 0.0f) {
				timeProgress = MIN(time - startTime, duration) / duration;
			} else {
				timeProgress = 1;
			}

			CGFloat p = easingFunction(localTime);
			if(isnan(p))
				p = 0;
			// interpolate and advance
			interpolate(valueType, valueCount, fromVec->data(), toVec->data(), currentVec->data(), p);
			progress = localTime;
			
			clampCurrentValue();
			return true;
		}

		return _POPBasicAnimationState::advance(time, dt, obj);
	}
};

typedef struct _POPCustomEasingAnimationState POPCustomEasingAnimationState;
