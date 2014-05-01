/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimator.h"
#import "POPAnimatorPrivate.h"

#import <list>
#import <objc/objc-auto.h>
#import <vector>

#import <QuartzCore/QuartzCore.h>

#import "POPAnimation.h"
#import "POPAnimationExtras.h"
#import "POPAnimationInternal.h"
#import "POPAnimationRuntime.h"
#import "POPBasicAnimationInternal.h"
#import "POPDecayAnimationInternal.h"
#import "POPSpringAnimationInternal.h"
#import "POPSpringSolver.h"

using namespace std;
using namespace POP;

#define ENABLE_LOGGING_DEBUG 0
#define ENABLE_LOGGING_INFO 0

#if ENABLE_LOGGING_DEBUG
#define FBLogAnimDebug NSLog
#else
#define FBLogAnimDebug(...)
#endif

#if ENABLE_LOGGING_INFO
#define FBLogAnimInfo NSLog
#else
#define FBLogAnimInfo(...)
#endif

class POPAnimatorItem
{
public:
  id __weak object;
  NSString *key;
  POPAnimation *animation;
  NSInteger refCount;
  id __unsafe_unretained unretainedObject;

  POPAnimatorItem(id o, NSString *k, POPAnimation *a) POP_NOTHROW
  {
    object = o;
    key = [k copy];
    animation = a;
    refCount = 1;
    unretainedObject = o;
  }

  ~POPAnimatorItem()
  {
  }

  bool operator==(const POPAnimatorItem& o) const {
    return unretainedObject == o.unretainedObject && animation == o.animation && [key isEqualToString:o.key];
  }

};

typedef std::shared_ptr<POPAnimatorItem> POPAnimatorItemRef;
typedef std::shared_ptr<const POPAnimatorItem> POPAnimatorItemConstRef;

typedef std::list<POPAnimatorItemRef> POPAnimatorItemList;
typedef POPAnimatorItemList::iterator POPAnimatorItemListIterator;
typedef POPAnimatorItemList::const_iterator POPAnimatorItemListConstIterator;

static BOOL _disableBackgroundThread = YES;

@interface POPAnimator ()
{
#if TARGET_OS_IPHONE
  CADisplayLink *_displayLink;
#else
  CVDisplayLinkRef _displayLink;
#endif
  POPAnimatorItemList _list;
  CFMutableDictionaryRef _dict;
  NSMutableArray *_observers;
  CFTimeInterval _slowMotionStartTime;
  CFTimeInterval _slowMotionLastTime;
  CFTimeInterval _slowMotionAccumulator;
  OSSpinLock _lock;
}
@end

@implementation POPAnimator

#if !TARGET_OS_IPHONE
static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *context)
{
  if (_disableBackgroundThread) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [(__bridge POPAnimator*)context render];
      });
  } else {
    [(__bridge POPAnimator*)context render];
  }
  return kCVReturnSuccess;
}
#endif

// call while holding lock
static void updateDisplayLink(POPAnimator *self)
{
  BOOL paused = 0 == self->_observers.count && self->_list.empty();

#if TARGET_OS_IPHONE
  if (paused != self->_displayLink.paused) {
    FBLogAnimInfo(paused ? @"pausing display link" : @"unpausing display link");
    self->_displayLink.paused = paused;
  }
#else
  if (paused == CVDisplayLinkIsRunning(self->_displayLink)) {
    FBLogAnimInfo(paused ? @"pausing display link" : @"unpausing display link");
    if (paused) {
      CVDisplayLinkStop(self->_displayLink);
    } else {
      CVDisplayLinkStart(self->_displayLink);
    }
  }
#endif
}

static void updateAnimatable(id obj, POPPropertyAnimationState *anim)
{
  // handle user-initiated stop or pause; hault animation
  if (!anim->active || anim->paused)
    return;

  if (anim->hasValue()) {
    pop_animatable_write_block write = anim->property.writeBlock;
    if (NULL == write)
      return;
    
    if (!anim->additive) {
      
      VectorRef currentVec = anim->currentValue();

      // update previous values; support animation convergence
      anim->previous2Vec = anim->previousVec;
      anim->previousVec = currentVec;

      // write value
      write(obj, currentVec->data());
      if (anim->tracing) {
        [anim->tracer writePropertyValue:POPBox(currentVec, anim->valueType, true)];
      }
    } else {
      pop_animatable_read_block read = anim->property.readBlock;
      if (NULL == read)
        return;
      
      // object value
      Vector4r objectValue = read_values(read, obj, anim->valueCount);

      // current animation value
      VectorRef currentVec = anim->currentValue();
      Vector4r currentValue = currentVec->vector4r();

      // determine animation change
      if (anim->previousVec) {
        Vector4r previousValue = anim->previousVec->vector4r();
        currentValue -= previousValue;
      }

      // add to object value
      currentValue += objectValue;
      
      // update previous values; support animation convergence
      anim->previous2Vec = anim->previousVec;
      anim->previousVec = currentVec;
      
      // write value
      write(obj, currentValue.data());
      if (anim->tracing) {
        [anim->tracer writePropertyValue:POPBox(currentVec, anim->valueType, true)];
      }
    }
  }
}

static void applyAnimationTime(id obj, POPAnimationState *state, CFTimeInterval time)
{
  if (!state->advanceTime(time, obj)) {
    return;
  }
  
  POPPropertyAnimationState *ps = dynamic_cast<POPPropertyAnimationState*>(state);
  if (NULL != ps) {
    updateAnimatable(obj, ps);
  }
  
  state->delegateApply();
}

static void applyAnimationProgress(id obj, POPAnimationState *state, CGFloat progress)
{
  POPPropertyAnimationState *ps = dynamic_cast<POPPropertyAnimationState*>(state);
  if (ps && !ps->advanceProgress(progress)) {
    return;
  }

  if (NULL != ps) {
    updateAnimatable(obj, ps);
  }
  
  state->delegateApply();
}

static POPAnimation *deleteDictEntry(POPAnimator *self, id __unsafe_unretained obj, NSString *key, BOOL cleanup = YES)
{
  POPAnimation *anim = nil;

  // lock
  OSSpinLockLock(&self->_lock);

  NSMutableDictionary *keyAnimationsDict = (__bridge id)CFDictionaryGetValue(self->_dict, (__bridge void *)obj);
  if (keyAnimationsDict) {

    anim = keyAnimationsDict[key];
    if (anim) {

      // remove key
      [keyAnimationsDict removeObjectForKey:key];

      // cleanup empty dictionaries
      if (cleanup && 0 == keyAnimationsDict.count) {
        CFDictionaryRemoveValue(self->_dict, (__bridge void *)obj);
      }
    }
  }

  // unlock
  OSSpinLockUnlock(&self->_lock);
  return anim;
}

static void stopAndCleanup(POPAnimator *self, POPAnimatorItemRef item, bool shouldRemove, bool finished)
{
  // remove
  if (shouldRemove) {
    deleteDictEntry(self, item->unretainedObject, item->key);
  }

  // stop
  POPAnimationState *state = POPAnimationGetState(item->animation);
  state->stop(shouldRemove, finished);

  if (shouldRemove) {
    // lock
    OSSpinLockLock(&self->_lock);

    // find item im list
    // may have already been removed on animationDidStop:
    POPAnimatorItemListIterator find_iter = find(self->_list.begin(), self->_list.end(), item);
    BOOL found = find_iter != self->_list.end();

    if (found) {
      self->_list.erase(find_iter);
    }

    // unlock
    OSSpinLockUnlock(&self->_lock);
  }
}

+ (id)sharedAnimator
{
  static POPAnimator* _animator = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _animator = [[POPAnimator alloc] init];
  });
  return _animator;
}

+ (BOOL)disableBackgroundThread
{
  return _disableBackgroundThread;
}

+ (void)setDisableBackgroundThread:(BOOL)flag
{
  _disableBackgroundThread = flag;
}

- (id)init
{
  self = [super init];
  if (nil == self) return nil;

#if TARGET_OS_IPHONE
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render)];
  _displayLink.paused = YES;
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
#else
  CVReturn ret = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
  ret = CVDisplayLinkSetOutputCallback(_displayLink, displayLinkCallback, (__bridge void *)self);
#endif

  _dict = POPDictionaryCreateMutableWeakPointerToStrongObject(5);
  _lock = OS_SPINLOCK_INIT;

  return self;
}

- (void)dealloc
{
#if TARGET_OS_IPHONE
  [_displayLink invalidate];
#else
  CVDisplayLinkStop(_displayLink);
  CVDisplayLinkRelease(_displayLink);
#endif
}

- (NSArray *)observers
{
  // lock
  OSSpinLockLock(&_lock);

  // get observers
  NSArray *observers = 0 != _observers.count ? [_observers copy] : nil;

  // unlock
  OSSpinLockUnlock(&_lock);
  return observers;
}

- (void)addAnimation:(POPAnimation *)anim forObject:(id)obj key:(NSString *)key
{
  if (!anim || !obj) {
    return;
  }

  // support arbitrarily many nil keys
  if (!key) {
    key = [[NSUUID UUID] UUIDString];
  }

  // lock
  OSSpinLockLock(&_lock);

  // get key, animation dict associated with object
  NSMutableDictionary *keyAnimationDict = (__bridge id)CFDictionaryGetValue(_dict, (__bridge void *)obj);

  // update associated animation state
  if (nil == keyAnimationDict) {
    keyAnimationDict = [NSMutableDictionary dictionary];
    CFDictionarySetValue(_dict, (__bridge void *)obj, (__bridge void *)keyAnimationDict);
  } else {
    // if the animation instance already exists, avoid cancelling only to restart
    POPAnimation *existingAnim = keyAnimationDict[key];
    if (existingAnim) {
      // unlock
      OSSpinLockUnlock(&_lock);
      if (existingAnim == anim) {
        return;
      }
      [self removeAnimationForObject:obj key:key cleanupDict:NO];
    }
  }
  keyAnimationDict[key] = anim;

  // create entry after potential removal
  POPAnimatorItemRef item(new POPAnimatorItem(obj, key, anim));
  _list.push_back(item);

  // support animation re-use, reset all animation state
  POPAnimationGetState(anim)->reset(true);

  // update display link
  updateDisplayLink(self);

  // unlock
  OSSpinLockUnlock(&_lock);
}

- (void)removeAllAnimationsForObject:(id)obj
{
  // lock
  OSSpinLockLock(&_lock);

  NSArray *animations = [(__bridge id)CFDictionaryGetValue(_dict, (__bridge void *)obj) allValues];
  CFDictionaryRemoveValue(_dict, (__bridge void *)obj);

  // unlock
  OSSpinLockUnlock(&_lock);

  if (0 == animations.count) {
    return;
  }

  NSHashTable *animationSet = [[NSHashTable alloc] initWithOptions:NSHashTableObjectPointerPersonality capacity:animations.count];
  for (id animation in animations) {
    [animationSet addObject:animation];
  }

  // lock
  OSSpinLockLock(&_lock);

  POPAnimatorItemRef item;
  for (auto iter = _list.begin(); iter != _list.end();) {
    item = *iter;
    if(![animationSet containsObject:item->animation]) {
      iter++;
    } else {
      iter = _list.erase(iter);
    }
  }

  // unlock
  OSSpinLockUnlock(&_lock);

  for (POPAnimation *anim in animations) {
    POPAnimationState *state = POPAnimationGetState(anim);
    state->stop(true, !state->active);
  }
}

- (void)removeAnimationForObject:(id)obj key:(NSString *)key cleanupDict:(BOOL)cleanupDict
{
  POPAnimation *anim = deleteDictEntry(self, obj, key, cleanupDict);
  if (nil == anim) {
    return;
  }

  // lock
  OSSpinLockLock(&_lock);

  POPAnimatorItemRef item;
  for (auto iter = _list.begin(); iter != _list.end();) {
    item = *iter;
    if(anim == item->animation) {
      _list.erase(iter);
      break;
    } else {
      iter++;
    }
  }

  // unlock
  OSSpinLockUnlock(&_lock);

  // stop animation and callout
  POPAnimationState *state = POPAnimationGetState(anim);
  state->stop(true, (!state->active && !state->paused));
}

- (void)removeAnimationForObject:(id)obj key:(NSString *)key
{
  [self removeAnimationForObject:obj key:key cleanupDict:YES];
}

- (NSArray *)animationKeysForObject:(id)obj
{
  // lock
  OSSpinLockLock(&_lock);

  // get keys
  NSArray *keys = [(__bridge id)CFDictionaryGetValue(_dict, (__bridge void *)obj) allKeys];

  // unlock
  OSSpinLockUnlock(&_lock);
  return keys;
}

- (id)animationForObject:(id)obj key:(NSString *)key
{
  // lock
  OSSpinLockLock(&_lock);

  // lookup animation
  NSDictionary *keyAnimationsDict = (__bridge id)CFDictionaryGetValue(_dict, (__bridge void *)obj);
  POPAnimation *animation = keyAnimationsDict[key];

  // unlock
  OSSpinLockUnlock(&_lock);
  return animation;
}

- (void)render
{
  CFTimeInterval time = CACurrentMediaTime();

#if TARGET_IPHONE_SIMULATOR
  // support slow-motion animations
  time += _slowMotionAccumulator;
  float f = POPAnimationDragCoefficient();

  if (f > 1.0) {
    if (!_slowMotionStartTime) {
      _slowMotionStartTime = time;
    } else {
      time = (time - _slowMotionStartTime) / f + _slowMotionStartTime;
      _slowMotionLastTime = time;
    }
  } else if (_slowMotionStartTime) {
    CFTimeInterval dt = (_slowMotionLastTime - time);
    time += dt;
    _slowMotionAccumulator += dt;
    _slowMotionStartTime = 0;
  }
#endif

  [self renderTime:time];
}

- (void)renderTime:(CFTimeInterval)time
{
  // begin transaction with actions disabled
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  // notify delegate
  [_delegate animatorWillAnimate:self];

  // lock
  OSSpinLockLock(&_lock);

  // count active animations
  const NSUInteger count = _list.size();
  if (0 == count) {
    // unlock
    OSSpinLockUnlock(&_lock);
  } else {
    // copy list into vectory
    std::vector<POPAnimatorItemRef> vector{ std::begin(_list), std::end(_list) };

    // unlock
    OSSpinLockUnlock(&_lock);
    
    id obj;
    POPAnimation *anim;
    POPAnimationState *state;

    for (auto item : vector) {
      obj = item->object;
      anim = item->animation;
      state = POPAnimationGetState(anim);

      if (nil == obj) {

        // object exists not; stop animating
        NSAssert(item->unretainedObject, @"object should exist");
        stopAndCleanup(self, item, true, false);

      } else {
        // start if needed
        state->startIfNeeded(obj, time, _slowMotionAccumulator);

        // only run active, not paused animations
        if (state->active && !state->paused) {
          // object exists; animate
          applyAnimationTime(obj, state, time);

          FBLogAnimDebug(@"time:%f running:%@", time, item->animation);

          if (state->isDone()) {
            // set end value
            applyAnimationProgress(obj, state, 1.0);

            // finished succesfully, cleanup
            stopAndCleanup(self, item, state->removedOnCompletion, YES);
          }
        }
      }
    }
  }

  // notify observers
  for (id observer in self.observers) {
    [observer animatorDidAnimate:(id)self];
  }
  
  // lock
  OSSpinLockLock(&_lock);

  // update display link
  updateDisplayLink(self);

  // unlock
  OSSpinLockUnlock(&_lock);

  // notify delegate and commit
  [_delegate animatorDidAnimate:self];
  [CATransaction commit];
}

- (void)addObserver:(id<POPAnimatorObserving>)observer
{
  NSAssert(nil != observer, @"attempting to add nil %@ observer", self);
  if (nil == observer) {
    return;
  }

  // lock
  OSSpinLockLock(&_lock);

  if (!_observers) {
    // use ordered collection for deterministic callout
    _observers = [[NSMutableArray alloc] initWithCapacity:1];
  }

  [_observers addObject:observer];
  updateDisplayLink(self);

  // unlock
  OSSpinLockUnlock(&_lock);
}

- (void)removeObserver:(id<POPAnimatorObserving>)observer
{
  NSAssert(nil != observer, @"attempting to remove nil %@ observer", self);
  if (nil == observer) {
    return;
  }

  // lock
  OSSpinLockLock(&_lock);

  [_observers removeObject:observer];
  updateDisplayLink(self);

  // unlock
  OSSpinLockUnlock(&_lock);
}

@end
