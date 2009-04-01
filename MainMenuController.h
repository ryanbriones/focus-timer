#import <Cocoa/Cocoa.h>

@interface MainMenuController : NSObject {
  IBOutlet NSTextField *timerLabel;
  IBOutlet NSTextField *workTextField;
  IBOutlet NSTextField *breakTextField;
  IBOutlet NSTextField *cyclesTextField;
  IBOutlet NSButton *startButton;
  IBOutlet NSButton *stopButton;

  NSInteger workSeconds;
  NSInteger breakSeconds;
  NSInteger cycles;
  
  NSTimer *timer;
  BOOL isWorkTime;
  BOOL isBreakTime;
  NSInteger cyclesCompleted;
  NSDate *timerStarted;
}

@property NSInteger workSeconds;
@property NSInteger breakSeconds;
@property NSInteger cycles;
@property NSTimer *timer;

- (IBAction) startTimer: (id) sender;
- (void) startWorkTimer;
- (void) startBreakTimer;
- (IBAction) stopTimer: (id) sender;
- (void) stopWorkTimer;
- (void) stopBreakTimer;
- (void) updateTimer: (NSTimer *) notificationTimer;
- (BOOL) hasCompletedAllCycles;
- (void) alertEndOfWork;
- (void) alertEndOfBreak;
- (void) alertEndOfCycle;

@end
