//
//  PreferencesController.h
//  focus-timer
//
//  Created by Ryan Carmelo Briones on 4/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"


@interface PreferencesController : DBPrefsWindowController {
  IBOutlet NSView *generalPreferencesView;
  IBOutlet NSView *timersPreferencesView;
}

@end
