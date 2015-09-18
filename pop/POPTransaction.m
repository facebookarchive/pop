//
//  POPTransaction.m
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPTransaction.h"
#import "POPTransactionInternal.h"
#import "POPGroupAnimation.h"
#import "POPAnimation.h"
#import "POPBasicAnimation.h"

#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#import <libkern/OSAtomic.h>
#endif

@interface POPTransaction () {
  NSMapTable* _objectAnimationGroupMap;
  BOOL  _commited;
  NSRecursiveLock*  _lock;
}

@property (nonatomic,strong) NSMutableDictionary* transactionData;

- (void)addAnimation:(POPBasicAnimation*)anim forObject:(id)obj;
- (void)commit;

@end

@interface POPTransactionManager () {
  OSSpinLock  _lock;
  NSMapTable* _threadTransactionFILOMap;
  NSMutableArray* _commitedTransactions;
}

@end

@implementation POPTransactionManager

+ (instancetype)sharedManager
{
  static POPTransactionManager* _mngr = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _mngr = [[POPTransactionManager alloc] init];
  });
  return _mngr;
}

- (instancetype)init
{
  self = [super init];
  _lock = OS_SPINLOCK_INIT;
  _threadTransactionFILOMap = [NSMapTable weakToStrongObjectsMapTable];
  _commitedTransactions = [NSMutableArray array];
  return self;
}

- (BOOL)canAddAnimationForObject:(id)obj
{
  return [self currentTransaction] != nil;
}

- (void)addAnimation:(POPBasicAnimation*)animation forObject:(id)obj
{
  [[self currentTransaction] addAnimation:animation forObject:obj];
}

- (void)lock
{
  OSSpinLockLock(&_lock);
}

- (void)unlock
{
  OSSpinLockUnlock(&_lock);
}

- (POPTransaction*)currentTransaction
{
  POPTransaction* transaction = nil;
  
  [self lock];
  
  NSThread* thread = [NSThread currentThread];
  NSMutableArray* filo = [_threadTransactionFILOMap objectForKey:thread];
  transaction = filo.lastObject;

  [self unlock];
  
  return transaction;
}

- (void)beginTransaction
{
  [self lock];
  
  NSThread* thread = [NSThread currentThread];
  NSMutableArray* filo = [_threadTransactionFILOMap objectForKey:thread];
  if ( !filo ) {
    filo = [NSMutableArray array];
    [_threadTransactionFILOMap setObject:filo forKey:thread];
  }
  
  [self unlock];
  
  [filo addObject:[[POPTransaction alloc] init]];
}

- (void)commitTransaction
{
  [self lock];
  
  NSThread* thread = [NSThread currentThread];
  NSMutableArray* filo = [_threadTransactionFILOMap objectForKey:thread];
  
  NSAssert( filo, @"it's an error to commit a transaction when there is none", nil );
  
  POPTransaction* transaction = filo.firstObject;
  NSAssert( transaction, @"it's an error to commit a transaction when there is none", nil );
  
  [filo removeObjectAtIndex:0];
  [_commitedTransactions addObject:transaction];
  
  [self unlock];

  [transaction commit];
}

- (void)transactionDidComplete:(POPTransaction*)transaction
{
  [self lock];
  [_commitedTransactions removeObject:transaction];
  [self unlock];
}

- (id)valueForKey:(NSString *)key
{
  return [[self currentTransaction] valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
  [[self currentTransaction] setValue:value forKey:key];
}

@end

@implementation POPTransaction

@synthesize transactionData;

- (instancetype)init
{
  self = [super init];
  _objectAnimationGroupMap = [NSMapTable weakToStrongObjectsMapTable];
  _lock = [[NSRecursiveLock alloc] init];
  self.transactionData = [NSMutableDictionary dictionary];
  [self setValue:@(0.4) forKey:kPOPTransactionAnimationDuration];
  [self setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] forKey:kPOPTransactionAnimationTimingFunction];
  return self;
}

- (void)addAnimation:(POPBasicAnimation*)anim forObject:(id)obj
{
  [_lock lock];
  
  POPGroupAnimation* group = [_objectAnimationGroupMap objectForKey:obj];
  if ( !group )
  {
    group = [POPGroupAnimation animation];
    [_objectAnimationGroupMap setObject:group forKey:obj];
  }

  [group addAnimation:anim];
  
  [_lock unlock];
}

- (void)_deleteAnimationGroupAndSendCompletionIfNeeded:(POPAnimation*)group
{
  void(^completion)(void) = nil;
  BOOL sendCompletion = NO;
  
  [_lock lock];
  
  completion = [self valueForKey:kPOPTransactionCompletionBlock];
  
  // find the group
  NSArray* allKeys = [[_objectAnimationGroupMap keyEnumerator] allObjects];
  for ( id obj in allKeys ) {
    
    POPGroupAnimation* testGroup = [_objectAnimationGroupMap objectForKey:obj];
    if ( testGroup == group )
    {
      [_objectAnimationGroupMap removeObjectForKey:obj];
      break;
    }
    
  }
  
  [_lock unlock];
  
  sendCompletion = completion && _objectAnimationGroupMap.count == 0;
  
  [[self class] unlock];
  
  if ( sendCompletion ) {
    if ( [NSThread isMainThread] )
      completion();
    else
      dispatch_async( dispatch_get_main_queue(), completion );
  }
  
  [[POPTransactionManager sharedManager] transactionDidComplete:self];
}

- (void)commit
{
  [_lock lock];
  
  NSAssert( _commited == NO, @"It's an error to commit a transaction more then once.", nil );

  _commited = YES;
  
  NSArray* objects  = [[_objectAnimationGroupMap keyEnumerator] allObjects];
  for ( id obj in objects )
  {
    POPGroupAnimation* group = [_objectAnimationGroupMap objectForKey:obj];
    
    __weak POPTransaction* weakMe = self;
    group.completionBlock = ^(POPAnimation* anim, BOOL finished) {

      POPTransaction* me = weakMe;
      if ( finished )
        [me _deleteAnimationGroupAndSendCompletionIfNeeded:anim];
      
    };
    
    // update all anims to use the current transactions info
    for ( POPBasicAnimation* anim in group.animations )
    {
      anim.duration = [[self valueForKey:kPOPTransactionAnimationDuration] doubleValue];
      anim.timingFunction = [self valueForKey:kPOPTransactionAnimationTimingFunction];
    }
    
    [obj pop_addAnimation:group forKey:[[NSUUID UUID] UUIDString]];
  }
  
  [_lock unlock];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
  if ( !key )
    return;
  
  [_lock lock];
  
  if ( !value )
    [self.transactionData removeObjectForKey:key];
  else
    [self.transactionData setObject:value forKey:key];
  
  [_lock unlock];
}

- (id)valueForKey:(NSString *)key
{
  if ( !key )
    return nil;
  
  [_lock lock];
  id val = [self.transactionData objectForKey:key];
  [_lock unlock];
  
  return val;
}

+ (void)begin
{
  [[POPTransactionManager sharedManager] beginTransaction];
}

+ (void)commit
{
  [[POPTransactionManager sharedManager] commitTransaction];
}

+ (void)lock
{
  [[POPTransactionManager sharedManager] lock];
}

+ (void)unlock
{
  [[POPTransactionManager sharedManager] unlock];
}

+ (CFTimeInterval)animationDuration
{
  return [[[POPTransactionManager sharedManager] valueForKey:kPOPTransactionAnimationDuration] doubleValue];
}

+ (void)setAnimationDuration:(CFTimeInterval)dur
{
  [[POPTransactionManager sharedManager] setValue:@(dur) forKey:kPOPTransactionAnimationDuration];
}

+ (CAMediaTimingFunction *)animationTimingFunction
{
  return [[POPTransactionManager sharedManager] valueForKey:kPOPTransactionAnimationDuration];
}

+ (void)setAnimationTimingFunction:(CAMediaTimingFunction *)function
{
  [[POPTransactionManager sharedManager] setValue:function forKey:kPOPTransactionAnimationTimingFunction];
}

+ (BOOL)disableActions
{
  return [[[POPTransactionManager sharedManager] valueForKey:kPOPTransactionDisableActions] boolValue];
}

+ (void)setDisableActions:(BOOL)flag
{
  [[POPTransactionManager sharedManager] setValue:@(flag) forKey:kPOPTransactionDisableActions];
}

+ (void (^)(void))completionBlock
{
  return [[POPTransactionManager sharedManager] valueForKey:kPOPTransactionCompletionBlock];
}

+ (void)setCompletionBlock:(void (^)(void))block
{
  [[POPTransactionManager sharedManager] setValue:block forKey:kPOPTransactionCompletionBlock];
}

@end

NSString * const kPOPTransactionAnimationDuration = @"kPOPTransactionAnimationDuration";
NSString * const kPOPTransactionDisableActions = @"kPOPTransactionDisableActions";
NSString * const kPOPTransactionAnimationTimingFunction = @"kPOPTransactionAnimationTimingFunction";
NSString * const kPOPTransactionCompletionBlock = @"kPOPTransactionCompletionBlock";
