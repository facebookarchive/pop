/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "POPAnimatable.h"

#import <pop/POP.h>

@implementation POPAnimatable
{
  BOOL _recording;
  NSMutableDictionary *_recordedValuesDict;
}
@synthesize radius = _radius;
@synthesize position = _position;

static void record_value(POPAnimatable *self, NSString *key, id value)
{
  if (!self->_recordedValuesDict) {
    self->_recordedValuesDict = [NSMutableDictionary new];
  }
  NSMutableArray *values = self->_recordedValuesDict[key];
  if (!values) {
    values = [NSMutableArray array];
    self->_recordedValuesDict[key] = values;
  }
  [values addObject:value];
}

static void record_value(POPAnimatable *self, NSString *key, float f)
{
  record_value(self, key, @(f));
}

static void record_value(POPAnimatable *self, NSString *key, CGPoint p)
{
  record_value(self, key, [NSValue valueWithCGPoint:p]);
}

- (void)setRadius:(float)radius
{
  _radius = radius;
  if (_recording) {
    record_value(self, @"radius", radius);
  }
}

- (void)setPosition:(CGPoint)position
{
  _position = position;
  if (_recording) {
    record_value(self, @"position", position);
  }
}

- (NSArray *)recordedValuesForKey:(NSString *)key
{
  return _recordedValuesDict[key];
}

- (void)startRecording
{
  _recording = YES;
}

- (void)stopRecording
{
  _recording = NO;
}

@end
