//
//  POPGroupAnimation.m
//  pop
//
//  Created by Alexander Cohen on 2015-09-17.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPGroupAnimation.h"
#import "POPAnimationInternal.h"
#import "POPAnimatorPrivate.h"

@implementation POPGroupAnimation {
  NSArray*      _animations;
  NSArray*      _animationKeys;
  BOOL          _addedAnimations;
}

+ (instancetype)animation
{
  return [[[self class] alloc] _init];
}

- (void)addAnimation:(POPAnimation*)animation
{
  NSMutableArray* anims = [_animations mutableCopy];
  [anims addObject:animation];
  [self setAnimations:anims];
}

- (void)setAnimations:(NSArray *)animations
{
  NSAssert( _addedAnimations == NO, @"cannot change the animations in an ongoing group animation");
  _animations = [animations copy];
}

- (NSArray*)animations
{
  return [_animations copy];
}

- (id)_init
{
  self = [super _init];
  if (nil != self) {
    _state->type = kPOPAnimationGroup;
    _animations = @[];
  }
  return self;
}

- (BOOL)_advance:(id)object currentTime:(CFTimeInterval)currentTime elapsedTime:(CFTimeInterval)elapsedTime
{
  // add all the animations if needed
  if ( !_addedAnimations )
  {
    NSLog( @"[%@:%p] _advance", NSStringFromClass(self.class), self );
    _addedAnimations = YES;
    
    NSMutableArray* keys = [NSMutableArray array];
    for ( POPAnimation* anim in self.animations )
    {
      NSString* key = [[NSUUID UUID] UUIDString];
      [keys addObject:key];
      [object pop_addAnimation:anim forKey:key];
    }
    _animationKeys = [keys copy];
  }
  
  // check for animation doneness
  NSUInteger animsLeft = 0;
  for ( NSString* key in _animationKeys )
  {
    POPAnimation* anim = [object pop_animationForKey:key];
    if ( anim )
      animsLeft++;
  }

  NSLog( @"   [%@:%p] animations left: %ld", NSStringFromClass(self.class), self, animsLeft );
  
  return animsLeft > 0;
}

- (void)setPaused:(BOOL)paused
{
  [super setPaused:paused];
  for ( POPAnimation* anim in _animations )
    anim.paused = paused;
}

- (void)setAutoreverses:(BOOL)autoreverses
{
  [super setAutoreverses:autoreverses];
  for ( POPAnimation* anim in _animations )
    anim.autoreverses = autoreverses;
}

- (void)setRepeatCount:(NSInteger)repeatCount
{
  [super setRepeatCount:repeatCount];
  for ( POPAnimation* anim in _animations )
    anim.repeatCount = repeatCount;
}

- (void)setRepeatForever:(BOOL)repeatForever
{
  [super setRepeatForever:repeatForever];
  for ( POPAnimation* anim in _animations )
    anim.repeatForever = repeatForever;
}

@end

@implementation POPGroupAnimation (NSCopying)

- (instancetype)copyWithZone:(NSZone *)zone {
  
  POPGroupAnimation *copy = [super copyWithZone:zone];
  
  if (copy) {
    copy.animations = self.animations;
  }
  
  return copy;
}

@end