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
#import "POPGroupAnimationInternal.h"

#import <QuartzCore/QuartzCore.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#endif

NSString * const kPOPTransactionAnimationDuration = @"kPOPTransactionAnimationDuration";
NSString * const kPOPTransactionDisableActions = @"kPOPTransactionDisableActions";
NSString * const kPOPTransactionAnimationTimingFunction = @"kPOPTransactionAnimationTimingFunction";
NSString * const kPOPTransactionCompletionBlock = @"kPOPTransactionCompletionBlock";
NSString * const kPOPTransactionAnimationDelay = @"kPOPTransactionAnimationDelay";

// from options
NSString * const kPOPTransactionAllowsUserInteraction = @"kPOPTransactionAllowsUserInteraction";
NSString * const kPOPTransactionAnimationRepeat = @"kPOPTransactionAnimationRepeat";
NSString * const kPOPTransactionAnimationAutoreverse = @"kPOPTransactionAnimationAutoreverse";

@interface POPTransaction () {
    NSMapTable* _objectAnimationGroupMap;
    BOOL  _commited;
    NSRecursiveLock*  _lock;
}

@property (nonatomic,strong) NSMutableDictionary* transactionData;

- (void)setAnimationOptions:(POPAnimationOptions)options;
- (void)addAnimation:(POPPropertyAnimation*)anim forObject:(id)obj;
- (void)commit;
- (POPPropertyAnimation*)animationForObject:(id)obj keyPath:(NSString*)keyPath;

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

- (POPPropertyAnimation*)animationForObject:(id)obj keyPath:(NSString*)keyPath
{
    return [[self currentTransaction] animationForObject:obj keyPath:keyPath];
}

- (void)addAnimation:(POPPropertyAnimation*)animation forObject:(id)obj
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

- (void)setAnimationOptions:(POPAnimationOptions)options
{
    [[self currentTransaction] setAnimationOptions:options];
}

@end

#define OPTION_ON(options,o) ( ( options & o ) == o )

@implementation POPTransaction

@synthesize transactionData;

- (instancetype)init
{
    self = [super init];
    _objectAnimationGroupMap = [NSMapTable weakToStrongObjectsMapTable];
    _lock = [[NSRecursiveLock alloc] init];
    self.transactionData = [NSMutableDictionary dictionary];
    [self setValue:@(0.4) forKey:kPOPTransactionAnimationDuration];
    [self setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault] forKey:kPOPTransactionAnimationTimingFunction];
    return self;
}

- (CAMediaTimingFunction*)_timingFunctionFromAnimationOptions:(POPAnimationOptions)options
{
    NSString* functionName = kCAMediaTimingFunctionDefault;
    
    if ( OPTION_ON(options, POPAnimationOptionCurveEaseInOut) )
        functionName = kCAMediaTimingFunctionEaseInEaseOut;
    else if ( OPTION_ON(options, POPAnimationOptionCurveEaseIn) )
        functionName = kCAMediaTimingFunctionEaseIn;
    else if ( OPTION_ON(options, POPAnimationOptionCurveEaseOut) )
        functionName = kCAMediaTimingFunctionEaseOut;
    else if ( OPTION_ON(options, POPAnimationOptionCurveLinear) )
        functionName = kCAMediaTimingFunctionLinear;
    
    return [CAMediaTimingFunction functionWithName:functionName];
}

- (void)setAnimationOptions:(POPAnimationOptions)options
{
    [_lock lock];
    [self setValue:@( OPTION_ON(options,POPAnimationOptionAllowUserInteraction) ) forKey:kPOPTransactionAllowsUserInteraction];
    [self setValue:@( OPTION_ON(options,POPAnimationOptionRepeat) ) forKey:kPOPTransactionAnimationRepeat];
    [self setValue:@( OPTION_ON(options,POPAnimationOptionAutoreverse) ) forKey:kPOPTransactionAnimationAutoreverse];
    [self setValue:[self _timingFunctionFromAnimationOptions:options] forKey:kPOPTransactionAnimationTimingFunction];
    [_lock unlock];
}

- (POPPropertyAnimation*)animationForObject:(id)obj keyPath:(NSString*)keyPath
{
    POPPropertyAnimation* anim = nil;
    
    [_lock lock];
    
    POPGroupAnimation* group = [_objectAnimationGroupMap objectForKey:obj];
    if ( group )
    {
        for ( POPAnimation* a in group.animations )
        {
            if ( [a isKindOfClass:[POPPropertyAnimation class]] ) {
                if ( [((POPPropertyAnimation*)a).keyPath isEqualToString:keyPath] ) {
                    anim = (POPPropertyAnimation*)a;
                    break;
                }
            }
        }
    }
    
    [_lock unlock];
    
    return anim;
}

- (void)addAnimation:(POPPropertyAnimation*)anim forObject:(id)obj
{
    [_lock lock];
    
    POPGroupAnimation* group = [_objectAnimationGroupMap objectForKey:obj];
    if ( !group )
    {
        group = [POPGroupAnimation animation];
        [_objectAnimationGroupMap setObject:group forKey:obj];
    }
    
    // update animation with current values
    anim.beginTime = [[self valueForKey:kPOPTransactionAnimationDelay] doubleValue];
    anim.repeatForever = [[self valueForKey:kPOPTransactionAnimationRepeat] boolValue];
    anim.autoreverses = [[self valueForKey:kPOPTransactionAnimationAutoreverse] boolValue];
    if ( [anim isKindOfClass:[POPBasicAnimation class]] ) {
        ((POPBasicAnimation*)anim).duration = [[self valueForKey:kPOPTransactionAnimationDuration] doubleValue];
        ((POPBasicAnimation*)anim).timingFunction = [self valueForKey:kPOPTransactionAnimationTimingFunction];
    }
    
    // add animation to group
    [group addAnimation:anim];
    
    [_lock unlock];
}

- (void)_deleteAnimationGroupAndSendCompletionIfNeeded:(POPAnimation*)group reestablishUserInteraction:(BOOL)reestablishUserInteraction
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
        
#if defined(POP_ALLOW_UIAPPLICATION_ACCESS)
        if ( reestablishUserInteraction )
            [[UIApplication sharedApplication] endIgnoringInteractionEvents];
#endif
        
        [self setValue:nil forKey:kPOPTransactionCompletionBlock];
        
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
        
        BOOL  allowUserInteraction = YES;
        
#if defined(POP_ALLOW_UIAPPLICATION_ACCESS)
        allowUserInteraction = [self valueForKey:kPOPTransactionAllowsUserInteraction];
#endif
        
        group.animationDidStartBlock = ^(POPAnimation* anim) {
            
#if defined(POP_ALLOW_UIAPPLICATION_ACCESS)
            if ( !allowUserInteraction )
                [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
#endif
            
        };
        
        group.completionBlock = ^(POPAnimation* anim, BOOL finished) {
            
            if ( finished )
                [self _deleteAnimationGroupAndSendCompletionIfNeeded:anim reestablishUserInteraction:!allowUserInteraction];
            
        };
        
        [obj pop_addAnimation:group forKey:[[NSUUID UUID] UUIDString]];
    }
    
    if ( objects.count == 0 )
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([[self valueForKey:kPOPTransactionAnimationDuration] doubleValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self _deleteAnimationGroupAndSendCompletionIfNeeded:nil reestablishUserInteraction:NO];
            
        });
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

+ (void)setAnimationDelay:(CFTimeInterval)delay
{
    [[POPTransactionManager sharedManager] setValue:@(delay) forKey:kPOPTransactionAnimationDelay];
}

+ (CFTimeInterval)animationDelay
{
    return [[[POPTransactionManager sharedManager] valueForKey:kPOPTransactionAnimationDelay] doubleValue];
}

+ (void)setAnimationOptions:(POPAnimationOptions)options
{
    [[POPTransactionManager sharedManager] setAnimationOptions:options];
}

@end

