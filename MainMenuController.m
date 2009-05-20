#import "MainMenuController.h"
#import "PreferencesController.h"
#import "FTTimerFormatter.h"
#import "FTSavedTimerDescriptionTransformer.h"

@implementation MainMenuController

@synthesize workSeconds;
@synthesize breakSeconds;
@synthesize cycles;
@synthesize timer;

+ (void) initialize {
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
  
  NSMutableArray *savedTimers = [NSMutableArray array];
  
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
- (NSDictionary *) registrationDictionaryForGrowl {
  NSMutableArray *notifications = [NSMutableArray array];
  [notifications addObject: @"Work Timer Finished"];
  [notifications addObject: @"Break Timer Finished"];
  [notifications addObject: @"All Cycles Complete"];
  
  NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            notifications, GROWL_NOTIFICATIONS_ALL,
                            notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
                            
  return regDict;
}

- (id) init {
  if(self = [super init]) {
    workSeconds = 1500;
    breakSeconds = 300;
    cycles = 4;
    
    isWorkTime = NO;
    isBreakTime = NO;
    cyclesCompleted = 0;
    
    FTSavedTimerDescriptionTransformer *stTransformer = [[FTSavedTimerDescriptionTransformer alloc] init];
    [NSValueTransformer setValueTransformer: stTransformer forName: @"FTSavedTimerDescriptionTransformer"];
  }
  
  return self;
}
- (void) dealloc {
  [self removeObserver: self forKeyPath: @"workSeconds"];
  [self removeObserver: self forKeyPath: @"breakSeconds"];
  
  [super dealloc];
}

- (void) awakeFromNib {
  [GrowlApplicationBridge setGrowlDelegate: self];

  [stopButton setEnabled: NO];
  [self addObserver: self forKeyPath: @"workSeconds" options: NSKeyValueObservingOptionNew context: NULL];
  [self addObserver: self forKeyPath: @"breakSeconds" options: NSKeyValueObservingOptionNew context: NULL];
}

- (IBAction) showPreferencesPanel: (id) sender {
  [[PreferencesController sharedPrefsWindowController] showWindow:nil];
	(void)sender;

}

- (void) updateTimerFieldsFromPreset: (id) sender {
  NSArray *savedTimers = [[NSUserDefaults standardUserDefaults] objectForKey: @"savedTimers"];
  NSDictionary *selectedPreset = [savedTimers objectAtIndex: ([sender indexOfSelectedItem] - 1)];
  
  self.workSeconds = [[selectedPreset objectForKey: @"workSeconds"] intValue];
  self.breakSeconds = [[selectedPreset objectForKey: @"breakSeconds"] intValue];
  self.cycles = [[selectedPreset objectForKey: @"cycles"] intValue];
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

- (void) stopWorkTimer {
  NSLog(@"stopping work timer");
  [timer invalidate];
}

- (void) stopBreakTimer {
  NSLog(@"stopping break timer");
  [timer invalidate];
}

- (void) updateTimer: (NSTimer *) notificationTimer {
  NSInteger secondsSinceTimerStarted = [[notificationTimer userInfo] timeIntervalSinceNow] * -1;
  NSInteger secondsLeftOnTimer = ( (isWorkTime ? workSeconds : breakSeconds) - secondsSinceTimerStarted );
  [timerLabel setIntValue: secondsLeftOnTimer];
  
  if(secondsLeftOnTimer == 0) {
    if(isBreakTime) cyclesCompleted++;
    NSString *timerAlerts = [[NSUserDefaults standardUserDefaults] objectForKey: @"timerAlerts"];
    
    if(isWorkTime && ![self hasCompletedAllCycles]) {
      [self stopWorkTimer];
      [self alertEndOfWork];
      
      if(timerAlerts == @"Use OS Alert Dialogs") {
        [self startBreakTimer];
      }
    } else if(isBreakTime && ![self hasCompletedAllCycles]) {
      [self stopBreakTimer];
      [self alertEndOfBreak];
      
      if(timerAlerts == @"Use OS Alert Dialogs") {
        [self startWorkTimer];
      }
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
  NSSound *alertSound = [NSSound soundNamed: @"Glass"];
  if(alertSound) [alertSound play];
  
  NSString *timerAlerts = [[NSUserDefaults standardUserDefaults] objectForKey: @"timerAlerts"];
  if(timerAlerts == @"Use Growl Notifications") {
    [GrowlApplicationBridge notifyWithTitle: @"Work Timer Finished" description: @"Time to take a break!"
                            notificationName: @"Work Timer Finished" iconData: nil 
                            priority: 0 isSticky: YES clickContext: @"StartBreakClick"];
  } else {  
    NSAlert *alert = [NSAlert alertWithMessageText: @"Time to take a break!" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"" ];
    [alert runModal];
  }
}
- (void) alertEndOfBreak {
  NSSound *alertSound = [NSSound soundNamed: @"Glass"];
  if(alertSound) [alertSound play];
  
  NSString *timerAlerts = [[NSUserDefaults standardUserDefaults] objectForKey: @"timerAlerts"];
  if(timerAlerts == @"Use Growl Notifications") {
    [GrowlApplicationBridge notifyWithTitle: @"Break Timer Finished" description: @"Time to get back to work!"
                            notificationName: @"Break Timer Finished" iconData: nil 
                            priority: 0 isSticky: YES clickContext: @"StartWorkClick"];
  } else {
    NSAlert *alert = [NSAlert alertWithMessageText: @"Time to get back to work!" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"" ];
    [alert runModal];
  }
}
- (void) alertEndOfCycle {
  NSInteger totalTimeInSeconds = (workSeconds * cycles) + (breakSeconds * cycles);
  NSLog(@"totalTime in seconds: %d", totalTimeInSeconds);
  NSString *totalTimeString;
  
  if(totalTimeInSeconds > 3600) {
    int hours = floor(totalTimeInSeconds / 3600);
    totalTimeInSeconds -= (hours * 3600);
    int minutes = floor(totalTimeInSeconds / 60);
    
    totalTimeString = [NSString stringWithFormat: @"%d hour %d minute", hours, minutes];
  } else if(totalTimeInSeconds > 60) {
    int minutes = floor(totalTimeInSeconds / 60);
    
    totalTimeString = [NSString stringWithFormat: @"%d minute", minutes];
  } else {
    totalTimeString = [NSString stringWithFormat: @"%d second", totalTimeInSeconds];
  }
  
  NSSound *alertSound = [NSSound soundNamed: @"Submarine"];
  if(alertSound) [alertSound play];

  NSString *timerAlerts = [[NSUserDefaults standardUserDefaults] objectForKey: @"timerAlerts"];
  if(timerAlerts == @"Use Growl Notifications") {
    NSString *description = [NSString stringWithFormat: @"You've finished a %@ cycle!", totalTimeString];
    [GrowlApplicationBridge notifyWithTitle: @"All Cycles Complete" description: description
                            notificationName: @"All Cycles Complete" iconData: nil 
                            priority: 0 isSticky: YES clickContext: nil];
  } else {
    NSAlert *alert = [NSAlert alertWithMessageText: @"Finished" defaultButton: nil alternateButton: nil otherButton: nil informativeTextWithFormat: @"You've finished a %@ cycle", totalTimeString ];
    [alert runModal];
  }
}

- (void) growlNotificationWasClicked: (id) clickContext {
  NSLog(@"got click: %@", clickContext);
  if([@"StartBreakClick" isEqualToString: clickContext]) {
    [self startBreakTimer];
  } else if([@"StartWorkClick" isEqualToString: clickContext]) {
    [self startWorkTimer];
  }
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed: (NSApplication *) theApplication { return YES; }

@end
