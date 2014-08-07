/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <pop/POPAnimationEvent.h>

@class POPAnimation;

/**
 @abstract Tracer of animation events to fasciliate unit testing & debugging.
 */
@interface POPAnimationTracer : NSObject

/**
 @abstract Start recording events.
 */
- (void)start;

/**
 @abstract Stop recording events.
 */
- (void)stop;

/**
 @abstract Resets any recoded events. Continues recording events if already started.
 */
- (void)reset;

/**
 @abstract Property representing all recorded events.
 @discussion Events are returned in order of occurence.
 */
@property (nonatomic, assign, readonly) NSArray *allEvents;

/**
 @abstract Property representing all recorded write events for convenience.
 @discussion Events are returned in order of occurence.
 */
@property (nonatomic, assign, readonly) NSArray *writeEvents;

/**
 @abstract Queries for events of specified type.
 @param type The type of event to return.
 @returns An array of events of specified type in order of occurence.
 */
- (NSArray *)eventsWithType:(POPAnimationEventType)type;

/**
 @abstract Property indicating whether tracer should automatically log events and reset collection on animation completion.
 */
@property (nonatomic, assign) BOOL shouldLogAndResetOnCompletion;

@end
