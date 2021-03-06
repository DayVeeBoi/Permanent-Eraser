//
//  PreferencesController.m
//  PermanentEraser
//
//  Created by Administrator on 6/16/10.
//  Copyright 2010 Edenwaith. All rights reserved.
//

#import "PreferencesController.h"

#define WINDOW_TITLE_HEIGHT 78

static NSString *GeneralToolbarItemIdentifier				=  @"General";
static NSString *UpdateToolbarItemIdentifier				=  @"Update";
static NSString *PlugInsToolbarItemIdentifier				=  @"Plug-Ins";

static PreferencesController *_sharedWindowController = nil;

@implementation PreferencesController

// Created: 2 July 2010 22:45
+ (PreferencesController *) sharedWindowController
{
	if (_sharedWindowController == NULL)
	{
		_sharedWindowController = [[self alloc] initWithWindowNibName: [self nibName]];
	}
	
	[_sharedWindowController window];	// load the nib
	// Do any preperations here
	[_sharedWindowController loadSettings];
	[_sharedWindowController showWindow: NULL];
	[[NSApplication sharedApplication] runModalForWindow: [_sharedWindowController window]];
	
	// Need to also register when the window closes
	
	return NULL;
}

// Created: 2 July 2010 22:45
+ (NSString *) nibName
{
	return @"Preferences";
}

// Created: 2 July 2010 22:45
- (void) dealloc
{
	// Unregister the NSWindowWillCloseNotification
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowWillCloseNotification object:  [_sharedWindowController window]];
	[super dealloc];
}

- (void) awakeFromNib
{
	toolbar = [[[NSToolbar alloc] initWithIdentifier:@"preferences toolbar"] autorelease];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
	[toolbar setSizeMode:NSToolbarSizeModeDefault];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	
	[toolbar setSelectedItemIdentifier:GeneralToolbarItemIdentifier];
	[[self window] setToolbar:toolbar];
	
	if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 4, 0}] == YES)
	{
		[[self window] setShowsToolbarButton:NO];	// Supported in Mac OS 10.4 and later
	}
	
	[self setActiveView:generalPreferenceView animate:NO];
	[[self window] setTitle:NSLocalizedString(GeneralToolbarItemIdentifier, nil)];
	[[self window] center];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(prefWindowClosed:)
												 name:NSWindowWillCloseNotification
											   object: [_sharedWindowController window]];
}


// =========================================================================
// (void) prefWindowClosed: (NSNotification *) aNotification
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 16 July 2010
// Version: 1 January 2012 21:29
// =========================================================================
- (void) prefWindowClosed: (NSNotification *) aNotification
{
	[[NSUserDefaults standardUserDefaults] synchronize];	// Force the defaults to update
	
	[[NSApplication sharedApplication] stopModal];
	
	[[NSApp delegate] preferencesClosed];
}


// =========================================================================
// (void) loadSettings
// -------------------------------------------------------------------------
// Load the settings from preferences.
// Some values (such as the checkboxes) are automatically set through bindings.
// -------------------------------------------------------------------------
// Created: 31 July 2010 15:35
// Version: 17 April 2011 19:44
// =========================================================================
- (void) loadSettings
{
	id opticalErasingLevel	= [[NSUserDefaults standardUserDefaults] objectForKey: @"OpticalDiscErasingLevel"];
	id fileErasingLevel		= [[NSUserDefaults standardUserDefaults] objectForKey: @"FileErasingLevel"];
	id lastCheckedDate		= [[NSUserDefaults standardUserDefaults] objectForKey: @"LastCheckedDate"];

	if (opticalErasingLevel != nil)
	{
		if ([opticalDiscErasingButton itemWithTitle: NSLocalizedString(opticalErasingLevel, nil)] != nil )
		{
			[opticalDiscErasingButton selectItemWithTitle: NSLocalizedString(opticalErasingLevel, nil)];
		}
	}

	if (fileErasingLevel != nil)
	{
		if ([fileErasingButton itemWithTitle: NSLocalizedString(fileErasingLevel, nil)] != nil)
		{
			[fileErasingButton selectItemWithTitle: NSLocalizedString(fileErasingLevel, nil)];
		}
	}

	// Mac OS 10.6+
	if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 6, 0}] == YES)	
	{
		pluginPath = [@"~/Library/Services/Erase.workflow" stringByExpandingTildeInPath];
	}
	else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 4, 0}] == YES)
	{	// Mac OS 10.4 + 10.5
		pluginPath = [@"~/Library/Contextual Menu Items/EraseCMI.plugin" stringByExpandingTildeInPath];
	}
	else
	{
		pluginPath = @"";
	}

	// Test this in Mac OS 10.3 to ensure this doesn't crash!
	if ([[NSFileManager defaultManager] fileExistsAtPath: pluginPath] == YES)
	{
		[pluginInstalledButton setState: NSOnState];
	}
	
	if ([pluginPath isEqualToString: @""] == YES)
	{
		[pluginInstalledButton setEnabled: NO];	// disable for Mac OS 10.3
		[pluginMsgField setStringValue: [NSString stringWithFormat: NSLocalizedString(@"NoPluginMessage", nil)]];
	}
	else	// For Mac OS 10.4+
	{
		[pluginMsgField setStringValue: [NSString stringWithFormat: NSLocalizedString(@"PluginInstallMessage", nil), [pluginPath lastPathComponent], [self displayLocalizedPath: [pluginPath stringByDeletingLastPathComponent]] ]];
	}
	
	if (lastCheckedDate != nil)
	{		
		[lastCheckedTextField setStringValue: [self formatLocalizedDate: lastCheckedDate]];
	}

}


#pragma mark -
#pragma mark Toolbar methods

// Version: 15 January 2012 1:00
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
#ifdef MAC_APP_STORE
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			nil];
#else
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			UpdateToolbarItemIdentifier,
			PlugInsToolbarItemIdentifier,
			nil];
#endif
}

// Version: 15 January 2012 1:00
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar 
{
#ifdef MAC_APP_STORE
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			nil];
#else
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			UpdateToolbarItemIdentifier,
			PlugInsToolbarItemIdentifier, // Don't show this one for Mac OS 10.3
			nil];
#endif

}

// Version: 15 January 2012 1:00
- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
#ifdef MAC_APP_STORE
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			nil];
#else
	return [NSArray arrayWithObjects:
			GeneralToolbarItemIdentifier,
			UpdateToolbarItemIdentifier,
			PlugInsToolbarItemIdentifier,
			nil];
#endif
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)willBeInserted 
{
	NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	if ([identifier isEqualToString:GeneralToolbarItemIdentifier]) 
	{
		[item setLabel: NSLocalizedString(@"General", nil)];
		[item setImage:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} 
	else if ([identifier isEqualToString:UpdateToolbarItemIdentifier]) 
	{
		[item setLabel:NSLocalizedString(@"Update", nil)];
		[item setImage:[NSImage imageNamed:@"software_update"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} 
	else if ([identifier isEqualToString:PlugInsToolbarItemIdentifier]) 
	{
		[item setLabel:NSLocalizedString(@"Plug-Ins", nil)];
		[item setImage:[NSImage imageNamed:@"plugin"]];
		[item setTarget:self];
		[item setAction:@selector(toggleActivePreferenceView:)];
	} 
	else
	{
		item = nil;
	}
	return item; 
}

// Version: 21 August 2007 21:24
- (void)togglePreferenceView:(NSString *)identifier
{
	NSView *view;
	
	if ([identifier isEqualToString:GeneralToolbarItemIdentifier])
		view = generalPreferenceView;
	else if ([identifier isEqualToString:UpdateToolbarItemIdentifier])
		view = updatePreferenceView;
	else if ([identifier isEqualToString:PlugInsToolbarItemIdentifier])
	{
		view = pluginsPreferenceView;
	}
	else	// Otherwise, default to the General view
		view = generalPreferenceView;
	
	[self setActiveView:view animate:YES];
	[[self window] setTitle:NSLocalizedString(identifier, nil)];

}


- (void)toggleActivePreferenceView:(id)sender
{
	NSView *view;
	
	if ([[sender itemIdentifier] isEqualToString:GeneralToolbarItemIdentifier])
		view = generalPreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:UpdateToolbarItemIdentifier])
		view = updatePreferenceView;
	else if ([[sender itemIdentifier] isEqualToString:PlugInsToolbarItemIdentifier])
		view = pluginsPreferenceView;
	else	// Otherwise, default to the General view
		view = generalPreferenceView;
	
	[self setActiveView:view animate:YES];
	[[self window] setTitle: NSLocalizedString([sender itemIdentifier], nil)];
		
}

- (void)setActiveView:(NSView *)view animate:(BOOL)flag
{
	// set the new frame and animate the change
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TITLE_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([[self window] frame]) - ([view frame].size.height + WINDOW_TITLE_HEIGHT);
	
	if ([[activeContentView subviews] count] != 0)
		[[[activeContentView subviews] objectAtIndex:0] removeFromSuperview];
	[[self window] setFrame:windowFrame display:YES animate:flag];
	
	[activeContentView setFrame:[view frame]];
	[activeContentView addSubview:view];
}

#pragma mark -
#pragma mark General

// =========================================================================
// (IBAction) fileErasingLevelSelected: (id) sender
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 18 July 2010 20:40
// Version: 27 April 2011 22:34
// =========================================================================
- (IBAction) fileErasingLevelSelected: (id) sender
{
	if ([[fileErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"FileErasingSimple", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: @"Simple (1x)" forKey:@"FileErasingLevel"];
	}
	else if ([[fileErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"FileErasingDoE", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: [fileErasingButton titleOfSelectedItem] forKey:@"FileErasingLevel"];
	}
	else if ([[fileErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"FileErasingMedium", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: [fileErasingButton titleOfSelectedItem] forKey:@"FileErasingLevel"];
	}
	else if ([[fileErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"FileErasingGutmann", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: [fileErasingButton titleOfSelectedItem] forKey:@"FileErasingLevel"];
	}
}


// =========================================================================
// (IBAction) opticalDiscErasingLevelSelected: (id) sender
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 18 July 2010 20:40
// Version: 9 March 2011 21:35
// =========================================================================
- (IBAction) opticalDiscErasingLevelSelected: (id) sender
{
	if ([[opticalDiscErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"Quick", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: @"Quick" forKey:@"OpticalDiscErasingLevel"];
	}
	else if ([[opticalDiscErasingButton titleOfSelectedItem] isEqualToString: NSLocalizedString(@"Complete", nil)])
	{
		[[NSUserDefaults standardUserDefaults] setObject: @"Complete" forKey:@"OpticalDiscErasingLevel"];
	}
}


// =========================================================================
// (IBAction) warnBeforeErasingSelected: (id) sender
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 18 July 2010 20:30
// Version: 18 July 2010 20:30
// =========================================================================
- (IBAction) warnBeforeErasingSelected: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool: [warnBeforeErasingButton state] forKey:@"WarnBeforeErasing"];
}


// =========================================================================
// (IBAction) playSoundsSelected: (id) sender
// -------------------------------------------------------------------------
// 
// -------------------------------------------------------------------------
// Created: 18 July 2010 20:50
// Version: 18 July 2010 20:50
// =========================================================================
- (IBAction) playSoundsSelected: (id) sender
{
	[[NSUserDefaults standardUserDefaults] setBool: [playSoundsButton state] forKey:@"BeepBeforeTerminating"];
}

#pragma mark -
#pragma mark Update

// =========================================================================
// (IBAction) checkForNewVersion: (id) sender
// -------------------------------------------------------------------------
// Added some new code to check if there is no network connection present.
// This resulted when the !%@# network went down at my house.  I learned
// something, but I still want my internet!  Screw MTV!  I want the Internet!
// -------------------------------------------------------------------------
// Created: 7. February 2004 19:25
// Version: 17 January 2011 20:39
// =========================================================================
- (IBAction) checkForNewVersion: (id) sender
{
    //NSString *currentVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *currentVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL: [NSURL URLWithString:@"http://www.edenwaith.com/xml/version.xml"]];
    NSString *latestVersionNumber = [productVersionDict valueForKey:@"Permanent Eraser"];
    int button = 0;
	
	NSDate *theDate = [NSDate date];
	// [lastCheckedTextField setStringValue: [theDate descriptionWithLocale:  [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]] ];
	[lastCheckedTextField setStringValue: [self formatLocalizedDate: theDate]];
	// Need save the date here in preferences...
	[[NSUserDefaults standardUserDefaults] setObject: theDate forKey: @"LastCheckedDate"];
	
    if ( latestVersionNumber == nil )
    {
        NSBeep();
		NSRunAlertPanel(NSLocalizedString(@"UpdateFailure", nil),
						NSLocalizedString(@"UpdateFailureMsg", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    else if ( [latestVersionNumber isEqualTo: currentVersionNumber] )
    {
		NSRunAlertPanel(NSLocalizedString(@"SoftwareUpToDate", nil),
						NSLocalizedString(@"RecentVersionMsg", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
    else
    {
		button = NSRunAlertPanel(NSLocalizedString(@"NewVersionAvailable", nil),
								 NSLocalizedString(@"NewVersionAvailableMsg", nil), NSLocalizedString(@"Download", nil), NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"MoreInfo", nil), latestVersionNumber);
		
        if (NSOKButton == button)
        {
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.edenwaith.com/downloads/permanent%20eraser.php"]];
        }
        else if (NSAlertOtherReturn == button) // More Info
        {
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://www.edenwaith.com/products/permanent%20eraser/"]];
        }
    }
}


// =========================================================================
// (NSString *) formatLocalizedDate: (NSDate *) theDate
// -------------------------------------------------------------------------
// NOTE: 2012-04-14 This method probably isn't necessary now, since the date
// format can be set within IB.
// -------------------------------------------------------------------------
// Created: 12 March 2011 20:52
// Version: 14 April 2012 18:07
// =========================================================================
- (NSString *) formatLocalizedDate: (NSDate *) theDate
{
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterFullStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSString *formattedDateString = [dateFormatter stringFromDate:theDate];
//	NSLog(@"Formatted date string for locale %@: %@", [[dateFormatter locale] localeIdentifier], formattedDateString);
	
	return (formattedDateString);
}


#pragma mark -
#pragma mark Plug-Ins

// =========================================================================
// (IBAction) installPluginSelected: (id) sender
// -------------------------------------------------------------------------
//
// -------------------------------------------------------------------------
// Created: 31 July 2010 16:23
// Version: 16 September 2012 16:51
// =========================================================================
- (IBAction) installPluginSelected: (id) sender
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if ([sender state] == NSOnState)	// Selected, install plug-in
	{
		// Copy plugin to the appropriate location
		// Mac OS 10.6+
		if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 6, 0}] == YES)
		{
			NSString *pluginSourcePath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @"Erase.workflow"];
			
			if ([fm fileExistsAtPath: pluginSourcePath] == YES) 
			{		
				NSError *err = nil;
				
				// If the ~/Library/Services folder does not exist, create it first
				if ([fm createDirectoryAtPath:[pluginPath stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: &err] == NO)
				{
					NSLog(@"Error: Failed to create directory %@ (%@)", [pluginPath stringByDeletingLastPathComponent], [err localizedDescription]);
				}
				
				if ([fm copyItemAtPath: pluginSourcePath toPath: pluginPath error: &err] == NO)
				{
					NSLog(@"Error: Failed to copy plug-in to %@ pluginPath (%@)", pluginPath, [err localizedDescription]);
				}
				
			}
		}
		// Mac OS X 10.5
		else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 5, 0}] == YES) // Mac OS X 10.5
		{
			NSString *pluginSourcePath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent: @"EraseCMI.plugin"];
			
			if ([fm fileExistsAtPath: pluginSourcePath] == YES) 
			{
				NSError *err = nil;
				
				// If the ~/Library/Contextual Menu Items/ folder does not exist, create it first
				if ([fm fileExistsAtPath: [pluginPath stringByDeletingLastPathComponent]] == NO)
				{
					if ([fm createDirectoryAtPath:[pluginPath stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: &err] == NO)
					{
						NSLog(@"Error: Failed to create directory %@ (%@)", [pluginPath stringByDeletingLastPathComponent], [err localizedDescription]);
					}				
				}
			
				if ([fm copyItemAtPath: pluginSourcePath toPath: pluginPath error: &err] == NO)
				{
					NSLog(@"Error: Failed to copy plug-in to %@ pluginPath (%@)", pluginPath, [err localizedDescription]);
				}
			}
		}
		
	}
	else	// Remove plug-in
	{
		if ([fm fileExistsAtPath: pluginPath] == YES)
		{
			NSError *err = nil;
			if ([fm removeItemAtPath: pluginPath error: &err] == NO)
			{
				NSLog(@"Error: Failed to delete file %@ (%@)", pluginPath, [err localizedDescription]);
			}
		}		 
	}
	
	// For the Contextual Menu Item plug-in, restart the Finder
	if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10, 6, 0}] == NO)
	{
		[self removeOldPlugin];
		[[NSTask launchedTaskWithLaunchPath:@"/usr/bin/killall" arguments:[NSArray arrayWithObject:@"Finder"]] waitUntilExit];
	}
}

// =========================================================================
// (void) removeOldPlugin
// -------------------------------------------------------------------------
// For Leopard, remove the old workflow which is no longer used due to the 
// new EraseCMI.plugin.
// -------------------------------------------------------------------------
// Created: 12 December 2015 21:30
// Version: 12 December 2015 21:30
// =========================================================================
- (void) removeOldPlugin
{
	NSString *oldPluginPath = [@"~/Library/Workflows/Applications/Finder/Permanent Eraser.workflow" stringByExpandingTildeInPath];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: oldPluginPath] == YES)
	{
		NSError *err = nil;
		if ([[NSFileManager defaultManager] removeItemAtPath: oldPluginPath error: &err] == NO)
		{
			NSLog(@"Error: Failed to delete file %@ (%@)", oldPluginPath, [err localizedDescription]);
		}
	}
}

// =========================================================================
// (NSString *) displayLocalizedPath: (NSString *) path
// -------------------------------------------------------------------------
// Parse through a path and display the localized name for each folder.
// -------------------------------------------------------------------------
// Created: 9 July 2011 19:58
// Version: 9 July 2011 21:25
// =========================================================================
- (NSString *) displayLocalizedPath: (NSString *) path
{
	if ([path isEqualToString:@"/"] == YES)
	{
		return (@"");
	}
	else 
	{
		return ([NSString stringWithFormat: @"%@/%@", [self displayLocalizedPath:[path stringByDeletingLastPathComponent]], [[NSFileManager defaultManager] displayNameAtPath: path]]);
	}
}

// =========================================================================
// (IBAction) openHelpPage: (id) sender
// -------------------------------------------------------------------------
//
// -------------------------------------------------------------------------
// Created: 14 November 2010 12:00
// Version: 14 November 2010 12:00
// =========================================================================
- (IBAction) openHelpPage: (id) sender
{
	NSString	*anchorName = NULL;
	NSString	*helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookFolder"];
	
	if ([sender tag] == 2)
	{
		anchorName = @"prefs-plugins-help";
	}
	
	if (anchorName != NULL)
	{
		[[NSHelpManager sharedHelpManager] openHelpAnchor: anchorName inBook: helpBookName];
	}
	else
	{
		[[NSApplication sharedApplication] showHelp: self];
	}
}

@end
