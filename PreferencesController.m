//
//  PreferencesController.m
//  focus-timer
//
//  Created by Ryan Carmelo Briones on 4/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController

- (void)setupToolbar
{
	[self addView:generalPreferencesView label:@"General"];
  [self addView:timersPreferencesView label:@"Timers"];
  	
		// Optional configuration settings.
	[self setCrossFade:[[NSUserDefaults standardUserDefaults] boolForKey:@"fade"]];
	// [self setShiftSlowsAnimation:[[NSUserDefaults standardUserDefaults] boolForKey:@"shiftSlowsAnimation"]];
}

@end
