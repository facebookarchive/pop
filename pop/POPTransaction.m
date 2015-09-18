//
//  POPTransaction.m
//  pop
//
//  Created by Alexander Cohen on 2015-09-18.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "POPTransaction.h"
#import <QuartzCore/QuartzCore.h>

@interface POPTransaction () {
  NSMutableArray* _animations;
}

@property (nonatomic,strong) NSMutableDictionary* transactionData;
@property (nonatomic,copy,readonly) NSArray* animations;

- (void)commit;

@end

@interface POPTransactionManager : NSObject {
  OSSpinLock  _lock;
  NSMapTable* _threadTransactionFILOMap;
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
  return self;
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

  [filo addObject:[[POPTransaction alloc] init]];

  [self unlock];
}

- (void)commitTransaction
{
  [self lock];
  
  NSThread* thread = [NSThread currentThread];
  NSMutableArray* filo = [_threadTransactionFILOMap objectForKey:thread];
  NSAssert( filo == nil, @"it's an error to commit a transaction when there is none", nil );
  
  POPTransaction* transaction = filo.firstObject;
  NSAssert( transaction == nil, @"it's an error to commit a transaction when there is none", nil );
  
  [filo removeObjectAtIndex:0];

  [transaction commit];
  
  [self unlock];
}

- (id)valueForKey:(NSString *)key
{
  id value = nil;
  [self lock];
  value = [[self currentTransaction] valueForKey:key];
  [self unlock];
  return value;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
  [self lock];
  [[self currentTransaction] setValue:value forKey:key];
  [self unlock];
}

@end

@implementation POPTransaction

@synthesize transactionData;

- (instancetype)init
{
  self = [super init];
  _animations = [NSMutableArray array];
  self.transactionData = [NSMutableDictionary dictionary];
  /*
  self.duration = 0.4;
  self.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
  self.actionsDisabled = NO;
  self.completionBlock = nil;
  */
  return self;
}

- (NSArray*)animations
{
  return [_animations copy];
}

- (void)commit
{
  
}

- (void)setValue:(id)value forKey:(NSString *)key
{
  if ( !key )
    return;
  
  if ( !value )
    [self.transactionData removeObjectForKey:key];
  else
    [self.transactionData setObject:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
  if ( !key )
    return nil;
  return [self.transactionData objectForKey:key];
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
