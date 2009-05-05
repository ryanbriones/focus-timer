#import "MainMenuController.h"
#import "PreferencesController.h"

@implementation MainMenuController

@synthesize workSeconds;
@synthesize breakSeconds;
@synthesize cycles;
@synthesize timer;

+ (void) initialize {
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  
  NSMutableArray *savedTimers = [[NSMutableArray alloc] init];
  
  NSMutableDictionary *pomodoroTimer = [NSMutableDictionary dictionary];
  [pomodoroTimer setObject: @"The Pomodoro Technique" forKey: @"name"];
  [pomodoroTimer setObject: [NSNumber numberWithInt: 1500] forKey: @"workSeconds"];
  [pomodoroTimer setObject: [NSNumber numberWithInt: 300] forKey: @"breakSeconds"];
  [pomodoroTimer setObject: [NSNumber numberWithInt: 4] forKey: @"cycles"];
  [savedTimers addObject: pomodoroTimer];
  
  NSMutableDictionary *procrastinationTimer = [NSMutableDictionary dictionary];
  [procrastinationTimer setObject: @"The Procrastination Hack" forKey: @"name"];
  [procrastinationTimer setObject: [NSNumber numberWithInt: 600] forKey: @"workSeconds"];
  [procrastinationTimer setObject: [NSNumber numberWithInt: 120] forKey: @"breakSeconds"];
  [procrastinationTimer setObject: [NSNumber numberWithInt: 5] forKey: @"cycles"];
  [savedTimers addObject: procrastinationTimer];
  
  [defaultValues setObject: savedTimers forKey: @"savedTimers"];  
  [defaultValues setObject: @"Use Growl Notifications" forKey: @"timerAlerts"];
  
  [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

- (id) init {
  if(self = [super init]) {
    workSeconds = 1500;
    breakSeconds = 300;
    cycles = 4;
    
    isWorkTime = NO;
    isBreakTime = NO;
    cyclesCompleted = 0;
  }
  
  return self;
}
- (void) dealloc {
  [self removeObserver: self forKeyPath: @"workSeconds"];
  [self removeObserver: self forKeyPath: @"breakSeconds"];
  
  [super dealloc];
}

- (void) awakeFromNib {
  [stopButton setEnabled: NO];
  [self addObserver: self forKeyPath: @"workSeconds" options: NSKeyValueObservingOptionNew context: NULL];
  [self addObserver: self forKeyPath: @"breakSeconds" options: NSKeyValueObservingOptionNew context: NULL];
}

- (IBAction) showPreferencesPanel: (id) sender {
  [[PreferencesController sharedPrefsWindowController] showWindow:nil];
	(void)sender;

}

- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context { 
  if([keyPath isEqual: @"workSeconds"]) {
    [workTextField validateEditing];
  } else if([keyPath isEqual: @"breakSeconds"]) {
    [breakTextField validateEditing];
  }
}

- (IBAction) startTimer: (id) sender {
  [startButton setEnabled: NO];
  [stopButton setEnabled: YES];
  
  [workTextField setEnabled: NO];
  [breakTextField setEnabled: NO];
  [cyclesTextField setEnabled: NO];
  
  cyclesCompleted = 0;
  [self startWorkTimer];
}
- (void) startWorkTimer {
  NSLog(@"starting work timer");
  
  isWorkTime = YES;
  isBreakTime = NO;
  
  [timerLabel setIntValue: workSeconds];
  
  if(timer) [timer invalidate];
  [self setTimer: [NSTimer scheduledTimerWithTimeInterval: 1.0
                                          target: self 
                                          selector: @selector(updateTimer:) 
                                          userInfo: [NSDate date] 
                                          repeats: YES]];
}

- (void) startBreakTimer {
  NSLog(@"starting break timer");
  
  isWorkTime = NO;
  isBreakTime = YES;
  
  [timerLabel setIntValue: breakSeconds];
  
  if(timer) [timer invalidate];
  [self setTimer: [NSTimer scheduledTimerWithTimeInterval: 1.0
                                          target: self 
                                          selector: @selector(updateTimer:) 
                                          userInfo: [NSDate date] 
                                          repeats: YES]];
}

- (IBAction) stopTimer: (id) sender {
  NSLog(@"stopping cycle");
  
  [timer invalidate];
  [timerLabel setIntValue: 0];
  
  isWorkTime ? [self stopWorkTimer] : [self stopBreakTimer];
  
  isWorkTime = NO;
  isBreakTime = NO;
  
  [startButton setEnabled: YES];
  [stopButton setEnabled: NO];
  
  [workTextField setEnabled: YES];
  [breakTextField setEnabled: YES];
  [cyclesTextField setEnabled: YES];
}

- (void) stopWorkTimer {}
- (void) stopBreakTimer {}

- (void) updateTimer: (NSTimer *) notificationTimer {
  NSInteger secondsSinceTimerStarted = [[notificationTimer userInfo] timeIntervalSinceNow] * -1;
  NSInteger secondsLeftOnTimer = ( (isWorkTime ? workSeconds : breakSeconds) - secondsSinceTimerStarted );
  [timerLabel setIntValue: secondsLeftOnTimer];
  
  if(secondsLeftOnTimer == 0) {
    if(isBreakTime) cyclesCompleted++;
    
    if(isWorkTime && ![self hasCompletedAllCycles]) {
      [self stopWorkTimer];
      [self alertEndOfWork];
      [self startBreakTimer];
    } else if(isBreakTime && ![self hasCompletedAllCycles]) {
      [self stopBreakTimer];
      [self alertEndOfBreak];
      [self startWorkTimer];
    } else {
      [self stopTimer: self];
      [self alertEndOfCycle];
    }
  }
}

- (BOOL) hasCompletedAllCycles {
  return cyclesCompleted == cycles;
}

- (void) alertEndOfWork {
  NSAlert *alert = [NSAlert alertWithMessageText: @"Time to take a break!" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"" ];
  NSSound *alertSound = [NSSound soundNamed: @"Glass"];
  
  if(alertSound) [alertSound play];
  [alert runModal];
}
- (void) alertEndOfBreak {
  NSAlert *alert = [NSAlert alertWithMessageText: @"Time to get back to work!" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"" ];
  NSSound *alertSound = [NSSound soundNamed: @"Glass"];
  
  if(alertSound) [alertSound play];
  [alert runModal];
}
- (void) alertEndOfCycle {
  NSLog(@"%d, %d, %d", workSeconds, breakSeconds, cycles);
  NSInteger totalTimeInSeconds = (workSeconds * cycles) + (breakSeconds * cycles);
  NSLog(@"totalTime in seconds: %d", totalTimeInSeconds);
  NSString *totalTimeString;
  
  if(totalTimeInSeconds > 3600) {
    int hours = floor(totalTimeInSeconds / 3600);
    totalTimeInSeconds -= (hours * 3600);
    int minutes = floor(totalTimeInSeconds / 60);
    
    totalTimeString = [NSString stringWithFormat: @"%d hour %d minute", hours, minutes];
  } else {
    int minutes = floor(totalTimeInSeconds / 60);
    
    totalTimeString = [NSString stringWithFormat: @"%d minute", minutes];
  }
  
  NSAlert *alert = [NSAlert alertWithMessageText: @"Finished" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"You've finished a %@ cycle", totalTimeString ];
  NSSound *alertSound = [NSSound soundNamed: @"Submarine"];
  
  if(alertSound) [alertSound play];
  [alert runModal];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication { return YES; }

@end
