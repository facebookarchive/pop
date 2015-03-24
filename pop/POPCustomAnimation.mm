/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimationInternal.h"

#import "POPCustomAnimation.h"

@interface POPCustomAnimation ()
@property (nonatomic, copy) POPCustomAnimationBlock animate;
@end

@implementation POPCustomAnimation
@synthesize currentTime = _currentTime;
@synthesize elapsedTime = _elapsedTime;
@synthesize animate = _animate;

+ (instancetype)animationWithBlock:(BOOL(^)(id target, POPCustomAnimation *))block
{
  POPCustomAnimation *b = [[self alloc] _init];
  b.animate = block;
  return b;
}

- (id)_init
{
  self = [super _init];
  if (nil != self) {
    _state->type = kPOPAnimationCustom;
  }
  return self;
}

- (CFTimeInterval)beginTime
{
  POPAnimationState *s = POPAnimationGetState(self);
  return s->startTime > 0 ? s->startTime : s->beginTime;
}

- (BOOL)_advance:(id)object currentTime:(CFTimeInterval)currentTime elapsedTime:(CFTimeInterval)elapsedTime
{
  _currentTime = currentTime;
  _elapsedTime = elapsedTime;
  return _animate(object, self);
}

- (void)_appendDescription:(NSMutableString *)s debug:(BOOL)debug
{
  [s appendFormat:@"; elapsedTime = %f; currentTime = %f;", _elapsedTime, _currentTime];
}

@end
