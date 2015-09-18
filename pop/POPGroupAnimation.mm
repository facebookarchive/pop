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

@interface POPGroupAnimation ()

@property (copy, nonatomic) void (^userAnimationDidStartBlock)(POPAnimation *anim);

@end

@implementation POPGroupAnimation {
  NSArray*      _animations;
  NSArray*      _animationKeys;
  BOOL          _addedAnimations;
}

@synthesize userAnimationDidStartBlock;

+ (instancetype)animation
{
  POPGroupAnimation* anim = [[[self class] alloc] _init];
  return anim;
}

- (void)setAnimations:(NSArray *)animations
{
  if ( _addedAnimations )
    return;
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
  }
  return self;
}

- (BOOL)_advance:(id)object currentTime:(CFTimeInterval)currentTime elapsedTime:(CFTimeInterval)elapsedTime
{
  // add all the animations if needed
  if ( !_addedAnimations )
  {
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