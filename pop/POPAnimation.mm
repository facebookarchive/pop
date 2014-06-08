/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationInternal.h"
#import "POPAnimationTracerInternal.h"

#import <objc/runtime.h>

#import "POPAnimationExtras.h"
#import "POPAnimationRuntime.h"
#import "POPAnimatorPrivate.h"
#import "POPAction.h"

using namespace POP;

#pragma mark - POPAnimation

@implementation POPAnimation
@synthesize solver = _solver;
@synthesize currentValue = _currentValue;
@synthesize progressMarkers = _progressMarkers;

#pragma mark - Lifecycle

- (id)init
{
  [NSException raise:NSStringFromClass([self class]) format:@"Attempting to instantiate an abstract class. Use a concrete subclass instead."];
  return nil;
}

- (id)_init
{
  self = [super init];
  if (nil != self) {
    [self _initState];
  }
  return self;
}

- (void)_initState
{
  _state = new POPAnimationState(self);
}

- (void)dealloc
{
  if (_state) {
    delete _state;
    _state = NULL;
  };
}

#pragma mark - Properties

- (id)delegate
{
  return _state->delegate;
}

- (void)setDelegate:(id)delegate
{
  _state->setDelegate(delegate);
}

- (BOOL)isPaused
{
  return _state->paused;
}

- (void)setPaused:(BOOL)paused
{
  _state->setPaused(paused ? true : false);
}

FB_PROPERTY_GET(POPAnimationState, type, POPAnimationType);
DEFINE_RW_PROPERTY_OBJ_COPY(POPAnimationState, completionBlock, setCompletionBlock:, POPAnimationCompletionBlock);
DEFINE_RW_PROPERTY_OBJ_COPY(POPAnimationState, name, setName:, NSString*);
DEFINE_RW_PROPERTY(POPAnimationState, beginTime, setBeginTime:, CFTimeInterval);
DEFINE_RW_FLAG(POPAnimationState, removedOnCompletion, removedOnCompletion, setRemovedOnCompletion:);

- (id)valueForUndefinedKey:(NSString *)key
{
  return _state->dict[key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
  if (!value) {
    [_state->dict removeObjectForKey:key];
  } else {
    if (!_state->dict)
      _state->dict = [[NSMutableDictionary alloc] init];
    _state->dict[key] = value;
  }
}

- (POPAnimationTracer *)tracer
{
  if (!_state->tracer) {
    _state->tracer = [[POPAnimationTracer alloc] initWithAnimation:self];
  }
  return _state->tracer;
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p", NSStringFromClass([self class]), self];
  [self _appendDescription:s debug:NO];
  [s appendString:@">"];
  return s;
}

- (NSString *)debugDescription
{
  NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p", NSStringFromClass([self class]), self];
  [self _appendDescription:s debug:YES];
  [s appendString:@">"];
  return s;
}

#pragma mark - Utility

POPAnimationState *POPAnimationGetState(POPAnimation *a)
{
  return a->_state;
}

- (BOOL)_advance:(id)object currentTime:(CFTimeInterval)currentTime elapsedTime:(CFTimeInterval)elapsedTime
{
  return YES;
}

- (void)_appendDescription:(NSMutableString *)s debug:(BOOL)debug
{
  if (_state->name)
    [s appendFormat:@"; name = %@", _state->name];
  
  if (!self.removedOnCompletion)
    [s appendFormat:@"; removedOnCompletion = %@", POPStringFromBOOL(self.removedOnCompletion)];
  
  if (debug) {
    if (_state->active)
      [s appendFormat:@"; active = %@", POPStringFromBOOL(_state->active)];
    
    if (_state->paused)
      [s appendFormat:@"; paused = %@", POPStringFromBOOL(_state->paused)];
  }
  
  if (_state->beginTime) {
    [s appendFormat:@"; beginTime = %f", _state->beginTime];
  }
  
  for (NSString *key in _state->dict) {
    [s appendFormat:@"; %@ = %@", key, _state->dict[key]];
  }
}

@end


#pragma mark - POPPropertyAnimation

#pragma mark - POPBasicAnimation

#pragma mark - POPDecayAnimation

@implementation NSObject (POP)

- (void)pop_addAnimation:(POPAnimation *)anim forKey:(NSString *)key
{
  [[POPAnimator sharedAnimator] addAnimation:anim forObject:self key:key];
}

- (void)pop_removeAllAnimations
{
  [[POPAnimator sharedAnimator] removeAllAnimationsForObject:self];
}

- (void)pop_removeAnimationForKey:(NSString *)key
{
  [[POPAnimator sharedAnimator] removeAnimationForObject:self key:key];
}

- (NSArray *)pop_animationKeys
{
  return [[POPAnimator sharedAnimator] animationKeysForObject:self];
}

- (id)pop_animationForKey:(NSString *)key
{
  return [[POPAnimator sharedAnimator] animationForObject:self key:key];
}

@end

@implementation NSProxy (POP)

- (void)pop_addAnimation:(POPAnimation *)anim forKey:(NSString *)key
{
  [[POPAnimator sharedAnimator] addAnimation:anim forObject:self key:key];
}

- (void)pop_removeAllAnimations
{
  [[POPAnimator sharedAnimator] removeAllAnimationsForObject:self];
}

- (void)pop_removeAnimationForKey:(NSString *)key
{
  [[POPAnimator sharedAnimator] removeAnimationForObject:self key:key];
}

- (NSArray *)pop_animationKeys
{
  return [[POPAnimator sharedAnimator] animationKeysForObject:self];
}

- (id)pop_animationForKey:(NSString *)key
{
  return [[POPAnimator sharedAnimator] animationForObject:self key:key];
}

@end
