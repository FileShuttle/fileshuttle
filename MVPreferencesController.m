//
//  NAPreferencesController.m
//  FileShuttle
//
//  Created by Michael Villar on 8/15/11.
//

#import "MVPreferencesController.h"
#import "AHKeychain.h"
#import "MVDictionaryKeyCombo.h"

#define kMVGeneralIdentifier @"general"
#define kMVurlshorteningIdentifier @"urlshortening"
#define kMVConnectionIdentifier @"connection"


#define kMVTopMargin 78

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVPreferencesController ()

@property (strong, readwrite) NSString *selectedIdentifier;
@property (strong, readwrite) NSView *selectedView;
@property (assign, nonatomic) BOOL showDockIcon;
@property (assign, nonatomic) BOOL use_filename;
@property (assign, nonatomic) BOOL use_hash;
@property (retain) NSTimer *passwordTimer;

- (void)updateLaunchAtLoginFromValue;
- (void)savePassword;
- (void)setShowDockIconValue:(BOOL)show;
- (void)setFront;
- (void)layoutView:(BOOL)animated;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Launch At Login helper Methods
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs
                                       ForPath:(NSString *)appPath;
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs
                                        ForPath:(NSString *)appPath;
- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs
                                      ForPath:(NSString *)appPath;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVPreferencesController

@synthesize passwordTextField           = passwordTextField_,
            window                      = window_,
            toolbar                     = toolbar_,
            generalView                 = generalView_,
            urlshorteningView           = urlshorteningView_,
            connectionView              = connectionView_,
            showInPopUpButton           = showInPopUpButton_,
            shortenerSelectionPopUpButton        = shortenerSelectionPopUpButton_,
            shortenerApiTokenField       = shortenerApiTokenField_,
            setFilenamePopUpButton      = setFilenamePopUpButton_,
            clipboardRecorderControl	= clipboardRecorderControl_,
            selectedIdentifier          = selectedIdentifier_,
            selectedView                = selectedView_,
            showDockIcon                = showDockIcon_,
            passwordTimer               = passwordTimer_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(controlTextDidChange:)
                                               name:NSControlTextDidChangeNotification
                                             object:self.passwordTextField];
	
	NSString *password = @"";
    NSError *keychainError;
    AHKeychain *keychain = [AHKeychain loginKeychain];

    AHKeychainItem *keychainItem = [[AHKeychainItem alloc] init];
    keychainItem.service = @"FileShuttle";
    keychainItem.account = @"";
    if ([keychain getItem:keychainItem error:&keychainError]) {
        password = [keychainItem password];
    } 

	[self.passwordTextField setStringValue:password];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults addObserver:self
             forKeyPath:@"dock_icon"
                options:NSKeyValueObservingOptionNew
                context:nil];
	[defaults addObserver:self
             forKeyPath:@"launch_at_login"
                options:NSKeyValueObservingOptionNew
                context:nil];
	self.showDockIcon = ![[[[NSBundle mainBundle] infoDictionary] objectForKey:@"LSUIElement"]
                        boolValue];
	[self setShowDockIconValue:[defaults boolForKey:@"dock_icon"]];
	[self updateLaunchAtLoginFromValue];
	
	if([defaults boolForKey:@"dock_icon"]) {
		if([defaults boolForKey:@"menubar_icon"]) {
			[self.showInPopUpButton selectItemWithTag:2];
		}
		else {
			[self.showInPopUpButton selectItemWithTag:1];
		}
	}
	else
		[self.showInPopUpButton selectItemWithTag:0];
    
    if([defaults boolForKey:@"use_hash"]) {
		if([defaults boolForKey:@"use_filename"]) {
			[self.setFilenamePopUpButton selectItemWithTag:2];
		}
		else {
			[self.setFilenamePopUpButton selectItemWithTag:1];
		}
	}
	else
		[self.setFilenamePopUpButton selectItemWithTag:0];
    
    if([defaults boolForKey:@"url_shortener"]) {
        [self.shortenerSelectionPopUpButton setEnabled:YES];
    } else {
        [self.shortenerSelectionPopUpButton setEnabled:NO];
    }

        if([defaults integerForKey:@"selected_shortener"]) {
                [self.shortenerSelectionPopUpButton selectItemWithTag:[defaults integerForKey:@"selected_shortener"]];
            NSInteger tag = [self.shortenerSelectionPopUpButton selectedTag];
            // If shortener selected is bit.ly or j.mp ask for API key.
            if(tag == 2 || tag == 3) {
                [shortenerApiTokenField_ setEnabled:YES];
            } else {
                [shortenerApiTokenField_ setEnabled:NO];
            }
        }
        if([defaults objectForKey:@"api_shortener_token"]) {
                [self.shortenerApiTokenField setStringValue:[defaults objectForKey:@"api_shortener_token"]];
                [self.shortenerApiTokenField setEnabled:YES];
            }

	NSString *protocol = [defaults valueForKey:@"protocol"];
	if([protocol compare:@"SFTP"] == NSOrderedSame || [protocol compare:@"SCP"] == NSOrderedSame) {
		BOOL changePermissions = [defaults boolForKey:@"change_permissions"];
		self.changePermissionsCheckbox.enabled = changePermissions;
		self.changePermissionsCheckbox.state = changePermissions ? NSOnState : NSOffState;
		self.permissionsTextField.enabled = YES;
	} else {
		self.changePermissionsCheckbox.enabled = NO;
		self.changePermissionsCheckbox.state = NSOffState;
		self.permissionsTextField.enabled = NO;
	}
	
	self.clipboardRecorderControl.style = SRGreyStyle;
	self.clipboardRecorderControl.animates = YES;
	self.clipboardRecorderControl.canCaptureGlobalHotKeys = YES;
	self.clipboardRecorderControl.delegate = self;
	NSDictionary *dic = [defaults dictionaryForKey:@"clipboard_upload_shortcut"];
	if(dic) {
		self.clipboardRecorderControl.keyCombo = MVKeyComboFromDictionary(dic);
	}
    
    [self.toolbar setSelectedItemIdentifier:kMVGeneralIdentifier];
    self.selectedIdentifier = kMVGeneralIdentifier;
    self.selectedView = nil;
    [self layoutView:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if([keyPath isEqualToString:@"dock_icon"])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[self setShowDockIconValue:[defaults boolForKey:@"dock_icon"]];
	}
	else if([keyPath isEqualToString:@"launch_at_login"])
	{
		[self updateLaunchAtLoginFromValue];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IBActions methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)toolbarItemAction:(id)sender {
  NSString *selectedIdentifier = self.toolbar.selectedItemIdentifier;
  if([self.selectedIdentifier isEqualToString:selectedIdentifier])
    return;
  self.selectedIdentifier = selectedIdentifier;
  [self layoutView:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)protocolChanged:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *protocol = [defaults valueForKey:@"protocol"];
	
	NSString *port = @"21";
  if([protocol compare:@"SFTP"] == NSOrderedSame || [protocol compare:@"SCP"] == NSOrderedSame) {
		port = @"22";
		self.changePermissionsCheckbox.state = [defaults boolForKey:@"change_permissions"];
		self.permissionsTextField.enabled = [defaults boolForKey:@"change_permissions"];
    self.changePermissionsCheckbox.enabled = YES;
	} else {
		self.changePermissionsCheckbox.enabled = NO;
		self.changePermissionsCheckbox.state = NSOffState;
		self.permissionsTextField.enabled = NO;
	}
	[[NSUserDefaults standardUserDefaults] setValue:port forKey:@"port"];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)passwordChanged:(id)sender {
	[self savePassword];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)showInPopUpButtonChanged:(id)sender {
	NSInteger tag = [self.showInPopUpButton selectedTag];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if(tag == 0) {
		[defaults setBool:YES forKey:@"menubar_icon"];
		[defaults setBool:NO forKey:@"dock_icon"];
	}
	else if(tag == 1) {
		[defaults setBool:NO forKey:@"menubar_icon"];
		[defaults setBool:YES forKey:@"dock_icon"];
	}
	else if(tag == 2) {
		[defaults setBool:YES forKey:@"menubar_icon"];
		[defaults setBool:YES forKey:@"dock_icon"];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)setFilenamePopUpButtonChanged:(id)sender {
	NSInteger tag = [self.setFilenamePopUpButton selectedTag];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if(tag == 0) {
		[defaults setBool:YES forKey:@"use_filename"];
		[defaults setBool:NO forKey:@"use_hash"];
	}
	else if(tag == 1) {
		[defaults setBool:NO forKey:@"use_filename"];
		[defaults setBool:YES forKey:@"use_hash"];
	}
	else if(tag == 2) {
		[defaults setBool:YES forKey:@"use_filename"];
		[defaults setBool:YES forKey:@"use_hash"];
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)shortenerSelectionPopUpButtonChanged:(id)sender {
        NSInteger tag = [self.shortenerSelectionPopUpButton selectedTag];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:tag forKey:@"selected_shortener"];
        // If shortener selected is bit.ly or j.mp ask for API key.
        if(tag == 2 || tag == 3) {
                [shortenerApiTokenField_ setEnabled:YES];
            } else {
                    [shortenerApiTokenField_ setEnabled:NO];
                }
    }
///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)saveApiKey {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *key = [shortenerApiTokenField_ stringValue];
        [defaults setObject:key forKey:@"api_shortener_token"];
    }
///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)shortenerApiTokenChanged:(id)sender {
        [self saveApiKey];
}
///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)enableShortenerCheckboxChanged:(id)sender
{
    NSButton *checkbox = sender;
    BOOL enableShortener = checkbox.state == NSOnState;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:enableShortener forKey:@"url_shortener"];
    
    self.shortenerSelectionPopUpButton.enabled = enableShortener;

    if (enableShortener) {
        [self.shortenerSelectionPopUpButton becomeFirstResponder];
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)changePermissionsCheckboxChanged:(id)sender
{
    NSButton *checkbox = sender;
    BOOL changePermissions = checkbox.state == NSOnState;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:changePermissions forKey:@"change_permissions"];
    
    self.permissionsTextField.enabled = changePermissions;
    if (changePermissions) {
			[self.permissionsTextField becomeFirstResponder];
			if (![defaults stringForKey:@"permission_string"]) {
				[defaults setObject:@"644" forKey:@"permission_string"];
			}
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateLaunchAtLoginFromValue
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL launch = [defaults boolForKey:@"launch_at_login"];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                          kLSSharedFileListSessionLoginItems,
                                                          NULL);
	NSString *path = [[NSBundle mainBundle] bundlePath];
	BOOL alreadyLaunch = [self loginItemExistsWithLoginItemReference:loginItems
                                                           ForPath:path];
	if(launch != alreadyLaunch) {
		if(launch)
			[self enableLoginItemWithLoginItemsReference:loginItems ForPath:path];
		else
			[self disableLoginItemWithLoginItemsReference:loginItems ForPath:path];
	}
	CFRelease(loginItems);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)savePassword
{
	NSString *password = [self.passwordTextField stringValue];
    NSError *keychainError;
    AHKeychain *keychain = [AHKeychain loginKeychain];
    AHKeychainItem *item = [[AHKeychainItem alloc] init];
    item.service = @"FileShuttle";
    item.account = @"";
    item.password = password;
    
    [keychain saveItem:item error:&keychainError];

}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setShowDockIconValue:(BOOL)show
{
	if (show) {
		if (!self.showDockIcon) {
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			OSStatus returnCode = TransformProcessType(& psn,
                                                 kProcessTransformToForegroundApplication);
			if( returnCode == 0) {
                NSRunningApplication* app = [NSRunningApplication
                                             runningApplicationWithProcessIdentifier: pID];
                [app activateWithOptions: NSApplicationActivateAllWindows];

				self.showDockIcon = YES;
				[self performSelector:@selector(setFront) withObject:nil afterDelay:0.5];
			} else {
				NSLog(@"Could not bring the application to front. Error %d", (int)returnCode);
			}
		}
	}
	else {
		if(self.showDockIcon) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"Restart"];
			[alert setMessageText:@"You must now restart"];
			[alert setInformativeText:@"This change requires to restart the application"];
			[alert setAlertStyle:NSWarningAlertStyle];

            [alert beginSheetModalForWindow: self.window completionHandler: ^(NSInteger returnCode){
                if (returnCode==NSAlertFirstButtonReturn) {
                    [NSTask launchedTaskWithLaunchPath:@"/bin/sh"
                                             arguments:[NSArray arrayWithObjects:@"-c",
                                                        [NSString stringWithFormat:
                                                         @"sleep 1 ; /usr/bin/open '%@'",
                                                         [[NSBundle mainBundle] bundlePath]],
                                                        nil]];
                    [NSApp terminate:self];
                }
            }
             ];

        }
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFront
{
    NSRunningApplication* app = [NSRunningApplication
                                 runningApplicationWithProcessIdentifier: pID];
    [app activateWithOptions: NSApplicationActivateAllWindows];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutView:(BOOL)animated
{
  NSView *nextView = nil;
  if([self.selectedIdentifier isEqualToString:kMVGeneralIdentifier])
    nextView = self.generalView;
  else if([self.selectedIdentifier isEqualToString:kMVurlshorteningIdentifier])
    nextView = self.urlshorteningView;
  else if([self.selectedIdentifier isEqualToString:kMVConnectionIdentifier])
      nextView = self.connectionView;
  
  if(nextView != self.selectedView)
  {
    if(self.selectedView)
      [self.selectedView removeFromSuperview];
    
    CGRect windowFrame = self.window.frame;
    windowFrame.size.height = nextView.frame.size.height + kMVTopMargin;
    windowFrame.origin.y += self.window.frame.size.height - windowFrame.size.height;
    
    [self.window setFrame:windowFrame display:YES animate:animated];
    
    [self.window.contentView addSubview:nextView];
    
    self.selectedView = nextView;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Launch At Login helper Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)enableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs
                                       ForPath:(NSString *)appPath
{
	// We call LSSharedFileListInsertItemURL to insert the item at the bottom of Login Items list.
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(theLoginItemsRefs,
                                                               kLSSharedFileListItemLast,
                                                               NULL, NULL, url, NULL, NULL);
	if (item)
		CFRelease(item);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)disableLoginItemWithLoginItemsReference:(LSSharedFileListRef )theLoginItemsRefs
                                        ForPath:(NSString *)appPath
{
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        if (LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL) == noErr) {
			if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
				LSSharedFileListItemRemove(theLoginItemsRefs, itemRef); // Deleting the item
			}
			// Docs for LSSharedFileListItemResolve say we're responsible
			// for releasing the CFURLRef that is returned
			if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)loginItemExistsWithLoginItemReference:(LSSharedFileListRef)theLoginItemsRefs
                                      ForPath:(NSString *)appPath
{
	BOOL found = NO;
	UInt32 seedValue;
	CFURLRef thePath = NULL;
	
	// We're going to grab the contents of the shared file list (LSSharedFileListItemRef objects)
	// and pop it in an array so we can iterate through it to find our item.
	CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(theLoginItemsRefs, &seedValue);
	for (id item in (NSArray *)loginItemsArray) {
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
        if (LSSharedFileListItemCopyResolvedURL(itemRef, 0, NULL) == noErr) {
            if ([[(NSURL *)thePath path] hasPrefix:appPath]) {
				found = YES;
				break;
			}
      // Docs for LSSharedFileListItemResolve say we're responsible
      // for releasing the CFURLRef that is returned
      if (thePath != NULL) CFRelease(thePath);
		}
	}
	if (loginItemsArray != NULL) CFRelease(loginItemsArray);
	
	return found;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSTextFieldDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if(self.passwordTimer)
		[self.passwordTimer invalidate];
	self.passwordTimer = [NSTimer scheduledTimerWithTimeInterval:2 
                                                        target:self 
                                                      selector:@selector(savePassword) 
                                                      userInfo:nil 
                                                       repeats:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark SRRecorderDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder 
       keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setValue:MVDictionaryFromKeyCombo(newKeyCombo)
              forKey:@"clipboard_upload_shortcut"];
}

@end
