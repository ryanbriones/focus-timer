//
//  FTSavedTimerDescriptionTransformer.m
//  focus-timer
//
//  Created by Ryan Carmelo Briones on 5/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "FTSavedTimerDescriptionTransformer.h"
#import "FTTimerFormatter.h"


@implementation FTSavedTimerDescriptionTransformer

+ (Class) transformedValueClass { return [NSArray class]; }
+ (BOOL) allowsReverseTransformation { return NO; }

- (id) transformedValue: (id) value {
  if(value == nil) return nil;
  
  NSMutableArray *newValue = [NSMutableArray array];
  FTTimerFormatter *tf = [[FTTimerFormatter alloc] init];
  
  if([value respondsToSelector: @selector(objectEnumerator)]) {
   NSEnumerator *timerEnum = [value objectEnumerator];
   NSDictionary *currentTimer;
   while(currentTimer = [timerEnum nextObject]) {
    NSString *workTimer = [tf stringForObjectValue: [currentTimer objectForKey: @"workSeconds"]];
    NSString *breakTimer = [tf stringForObjectValue: [currentTimer objectForKey: @"breakSeconds"]];
    [newValue addObject: [NSString stringWithFormat: @"%@ -- %@|%@|%@",
      [currentTimer objectForKey: @"name"], workTimer, breakTimer, [currentTimer objectForKey: @"cycles"]]];
   }
  } else {
    [NSException raise: NSInternalInconsistencyException format: @"Value (%@) does not respond to -objectForKey.", [value class]];
  }
  
  return newValue;
}

@end
