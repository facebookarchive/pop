/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreGraphics/CoreGraphics.h>

#import <Foundation/Foundation.h>

#import <QuartzCore/QuartzCore.h>

@interface POPAnimatable : NSObject

@property (nonatomic, assign) float radius;

@property (nonatomic, assign) CGPoint position;

- (NSArray *)recordedValuesForKey:(NSString *)key;

- (void)startRecording;

- (void)stopRecording;

@end
