#import "FTTimerFormatter.h"

@implementation FTTimerFormatter

- (id) init {
  [super init];
  
  return self;
}

- (NSString *) stringForObjectValue: (id) timeAsString {	
  int totalTimeInSeconds = [timeAsString integerValue];
  int remainder, hours, minutes, seconds;

  remainder = totalTimeInSeconds;
  
  hours = floor(remainder / 3600);
  remainder -= hours * 3600;

  minutes = floor(remainder / 60);
  remainder -= minutes * 60;

  seconds = remainder;

  if(hours > 0) {
    return [NSString stringWithFormat: @"%02d:%02d:%02d", hours, minutes, seconds];
  } else {
    return [NSString stringWithFormat: @"%02d:%02d", minutes, seconds];
  }
}

- (BOOL) getObjectValue: (id *) anObject forString: (NSString *) string errorDescription: (NSString **) error {
  if([string length] < 3) {
    *anObject = [NSNumber numberWithInt: [string intValue]];
    return YES;
  } else {
    int timerSeconds, minutes, seconds;
    NSArray *timerParts = [string componentsSeparatedByString: @":"];
    
    if([timerParts count] == 2) {
      timerSeconds = 0;
      
      NSMutableString *minutesString = [[NSMutableString alloc] init];
      [minutesString setString: [timerParts objectAtIndex: 0]];
      NSString *secondsString = [timerParts objectAtIndex: 1];

      if([secondsString length] == 3) {
	seconds = [[secondsString substringWithRange: NSMakeRange(1,2)] intValue];
	[minutesString appendString: [secondsString substringWithRange: NSMakeRange(0, 1)]];
	minutes = [[minutesString substringWithRange: NSMakeRange(1,2)] intValue];
      }

      if([secondsString length] == 1) {
	seconds = [secondsString intValue] * 10;
	minutes = [minutesString intValue]; 
      }

      if([secondsString length] == 2) {
	seconds = [secondsString intValue];
	minutes = [minutesString intValue]; 
      }

      timerSeconds += minutes * 60;
      timerSeconds += seconds;

      *anObject = [NSNumber numberWithInt: timerSeconds];
      return YES;
    } else if ([timerParts count] == 1) {
      timerSeconds = 0;

      minutes = [[timerParts objectAtIndex: 0] intValue] / 100;
      timerSeconds += minutes * 60;
      
      seconds = [[timerParts objectAtIndex: 0] intValue] % 100;
      timerSeconds += seconds;

      *anObject = [NSNumber numberWithInt: timerSeconds];
      return YES;
    }
  }

  return NO;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
  if(NSEqualRanges(NSMakeRange(2,1), [partialString rangeOfString: @":"])) {
    NSArray *timerParts = [partialString componentsSeparatedByString: @":"];
    int minutes, seconds;

    NSMutableString *minutesString = [[NSMutableString alloc] init];
    [minutesString setString: [timerParts objectAtIndex: 0]];
    NSString *secondsString = [timerParts objectAtIndex: 1];

    if([secondsString length] == 3) {
      seconds = [[secondsString substringWithRange: NSMakeRange(1,2)] intValue];
      [minutesString appendString: [secondsString substringWithRange: NSMakeRange(0, 1)]];
      minutes = [[minutesString substringWithRange: NSMakeRange(1,2)] intValue];
    } else if([minutesString length] == 1) {
           
    }

    if([secondsString length] == 1) {
      seconds = [secondsString intValue] * 10;
      minutes = [minutesString intValue]; 
    }

    if([secondsString length] == 2) {
      seconds = [secondsString intValue];
      minutes = [minutesString intValue];
    }

    if(seconds > 59 || minutes > 59) {
      *newString = nil;
      return NO;
    }

    return YES;
  } else if(NSEqualRanges(NSMakeRange(3,1), [partialString rangeOfString: @":"])) {
    *newString = nil;
    *error = @"test";
    return NO;
  }

  return YES;
}

@end
