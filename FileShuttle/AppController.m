//
//  AppController.m
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import "AppController.h"
#import "MVDictionaryKeyCombo.h"
#import "NSPasteboard+Files.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AppController ()

@property (retain) MVDockImage *dockImage;
@property (retain) MVScreenshotsListener *screenshotsDirectoryListener;
@property (retain) MVFileUploader *fileUploader;
@property (retain) NSTimer *restoreDockIconTimer;
@property (retain) NSStatusItem *statusItem;
@property (retain) MVStatusItemView *statusView;
@property (retain) NSMenu *statusMenu;
@property (retain) MVURLShortener *urlShortener;
@property (retain) MVZipFiles *zipFiles;
@property (assign) BOOL showDockIcon;
@property (retain) NSMutableArray *lastUploadedFilesMenuItems;
@property (retain) NSMenuItem *separatorMenuItem;
@property (retain) NSData *originalDockImageData;
@property (assign) KeyCombo registeredClipboardShortcut;
@property (assign) BOOL isRegisteredClipboardShortcut;

- (BOOL)areConnectionSettingsFilled;
- (void)uploadPNG:(NSData*)pngData;
- (void)uploadString:(NSString*)string;
- (void)uploadFiles:(NSArray*)filenames;
- (void)uploadFiles:(NSArray*)filenames
         deleteFile:(BOOL)deleteFiles;
- (void)setDisplayStatusItem:(BOOL)flag;
- (void)setRegisterClipboardShortcut:(BOOL)flag
                            keyCombo:(KeyCombo)keyCombo;
- (void)restoreDockIcon;
- (void)updateDockIcon;
- (void)displayCompletedIcons;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation AppController

@synthesize dockImage                       = dockImage_,
            screenshotsDirectoryListener    = screenshotsDirectoryListener_,
            fileUploader                    = fileUploader_,
            restoreDockIconTimer            = restoreDockIconTimer_,
            statusItem                      = statusItem_,
            statusView                      = statusView_,
            statusMenu                      = statusMenu_,
            preferencesWindow               = preferencesWindow_,
            urlShortener                    = urlShortener_,
            zipFiles                        = zipFiles_,
            showDockIcon                    = showDockIcon_,
            lastUploadedFilesMenuItems      = lastUploadedFilesMenuItems_,
            separatorMenuItem               = separatorMenuItem_,
            originalDockImageData           = originalDockImageData_,
            registeredClipboardShortcut     = registeredClipboardShortcut_,
            isRegisteredClipboardShortcut   = isRegisteredClipboardShortcut_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[dockImage_ release];
	[screenshotsDirectoryListener_ release];
	[fileUploader_ release];
	[restoreDockIconTimer_ release];
	[statusItem_ release];
	[statusView_ release];
	[statusMenu_ release];
	[urlShortener_ release];
	[zipFiles_ release];
	[lastUploadedFilesMenuItems_ release];
	[separatorMenuItem_ release];
	[originalDockImageData_ release];
	
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super init];
  if (self) {
		restoreDockIconTimer_ = nil;
		
		NSDictionary *defaultClipboardShortcutDic =
    MVDictionaryFromKeyCombo(
                             SRMakeKeyCombo(32 /* U */, NSCommandKeyMask | NSAlternateKeyMask));
		NSDictionary *defaultsPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"FTP", @"protocol",
                                   @"21", @"port",
                                   @"YES",@"upload_screenshots",
                                   @"NO",@"delete_screenshots",
                                   @"YES",@"url_shortener",
                                   @"NO",@"dock_icon",
                                   @"YES",@"menubar_icon",
                                   @"YES",@"use_filename",
                                   @"YES",@"use_hash",
                                   @"NO",@"launch_at_login",
                                   @"YES",@"growl",
                                   @"YES",@"clipboard_upload",
                                   defaultClipboardShortcutDic,@"clipboard_upload_shortcut",
                                   nil];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults:defaultsPrefs];
		
		if(![defaults boolForKey:@"dock_icon"] && ![defaults boolForKey:@"menubar_icon"])
		{
			[defaults setBool:YES forKey:@"menubar_icon"];
		}
      
        if(![defaults boolForKey:@"use_hash"] && ![defaults boolForKey:@"use_filename"])
        {
            [defaults setBool:YES forKey:@"use_hash"];
            [defaults setBool:YES forKey:@"use_filename"];
        }
		
		[defaults addObserver:self
               forKeyPath:@"upload_screenshots"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
		[defaults addObserver:self
               forKeyPath:@"menubar_icon"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
		[defaults addObserver:self
               forKeyPath:@"dock_icon"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
		[defaults addObserver:self
               forKeyPath:@"clipboard_upload"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
		[defaults addObserver:self
               forKeyPath:@"clipboard_upload_shortcut"
                  options:NSKeyValueObservingOptionNew
                  context:nil];
		
		showDockIcon_ = [defaults boolForKey:@"dock_icon"];
		
		dockImage_ = [[MVDockImage alloc] init];
		
		originalDockImageData_ = [[dockImage_ TIFFRepresentation] retain];
		
		fileUploader_ = [[MVFileUploader alloc] init];
		fileUploader_.delegate = self;
		
		separatorMenuItem_ = [[NSMenuItem separatorItem] retain];
		
		lastUploadedFilesMenuItems_ = [[NSMutableArray alloc] init];
		
		// listener for this directory
		screenshotsDirectoryListener_ = [[MVScreenshotsListener alloc] init];
		[screenshotsDirectoryListener_ setListening:[defaults boolForKey:@"upload_screenshots"]];
		[screenshotsDirectoryListener_ setDelegate:self];
		
		// status menu
		statusMenu_ = [[NSMenu alloc] init];
		[statusMenu_ addItemWithTitle:@"Preferences…"
                           action:@selector(openPreferences)
                    keyEquivalent:@""];
		[statusMenu_ addItemWithTitle:@"Quit"
                           action:@selector(quit)
                    keyEquivalent:@""];
		
		// status bar item
		[self setDisplayStatusItem:[defaults boolForKey:@"menubar_icon"]];
		
		// url shortener
		urlShortener_ = [[MVURLShortener alloc] init];
		
		// zip files
		zipFiles_ = [[MVZipFiles alloc] init];
		
		// clipboard shortcut
		isRegisteredClipboardShortcut_ = NO;
		BOOL clipboardUpload = [defaults boolForKey:@"clipboard_upload"];
		if(clipboardUpload) {
			NSDictionary *clipboardDic = [defaults dictionaryForKey:@"clipboard_upload_shortcut"];
			if(clipboardDic)
				[self setRegisterClipboardShortcut:YES
                                  keyCombo:MVKeyComboFromDictionary(clipboardDic)];
		}
  }
  
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(windowDidUpdate:)
                                               name:NSWindowDidUpdateNotification
                                             object:nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if([keyPath isEqualToString:@"upload_screenshots"])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[self.screenshotsDirectoryListener setListening:[defaults boolForKey:@"upload_screenshots"]];
	}
	else if([keyPath isEqualToString:@"menubar_icon"])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[self setDisplayStatusItem:[defaults boolForKey:@"menubar_icon"]];
	}
	else if([keyPath isEqualToString:@"dock_icon"])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		self.showDockIcon = [defaults boolForKey:@"dock_icon"];
		[self restoreDockIcon];
	}
	else if([keyPath isEqualToString:@"clipboard_upload"]
					|| [keyPath isEqualToString:@"clipboard_upload_shortcut"])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *dic = [defaults dictionaryForKey:@"clipboard_upload_shortcut"];
		[self setRegisterClipboardShortcut:[defaults boolForKey:@"clipboard_upload"]
                              keyCombo:MVKeyComboFromDictionary(dic)];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSApp setServicesProvider:self];
	[self updateDockIcon];
	
	if(![self areConnectionSettingsFilled])
		[self.preferencesWindow makeKeyAndOrderFront:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)application:(NSApplication *)sender
          openFiles:(NSArray *)filenames
{
	[self uploadFiles:filenames];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)doString:(NSPasteboard *)pboard
        userData:(NSString *)userData
           error:(NSString **)error
{
	NSArray *types = [pboard types];
	if([types containsObject:NSStringPboardType]) {
		NSString *pboardString = [pboard stringForType:NSStringPboardType];
		[self uploadString:pboardString];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MenuItem Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)openPreferences
{
	[self.preferencesWindow makeKeyAndOrderFront:self];
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	SetFrontProcess(&psn);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)quit
{
	[NSApp terminate:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)areConnectionSettingsFilled
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *protocol = [defaults stringForKey:@"protocol"];
	NSString *hostname = [defaults stringForKey:@"host"];
	NSString *username = [defaults stringForKey:@"username"];
	NSString *baseurl = [defaults stringForKey:@"baseurl"];
	
	return !(!protocol || [protocol length] == 0 || !hostname || [hostname length] == 0
           || !username || [username length] == 0 || !baseurl || [baseurl length] == 0);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadPNG:(NSData*)pngData
{
	NSString *path = @"/tmp/image.png";
	[pngData writeToFile:path atomically:YES];
	[self uploadFiles:[NSArray arrayWithObject:path]
         deleteFile:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadString:(NSString*)string
{
	NSString *path = @"/tmp/snippet.txt";
	[string writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
	[self uploadFiles:[NSArray arrayWithObject:path]
         deleteFile:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadFiles:(NSArray*)filenames
{
	[self uploadFiles:filenames
         deleteFile:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadFiles:(NSArray*)filenames
         deleteFile:(BOOL)deleteFile
{
	if(![self areConnectionSettingsFilled])
	{
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"growl"])
        {
            NSString *title = @"Upload failed";
            NSString *description = @"Please check your connection configuration";
            NSString *notificationName = @"Bad configuration";
            
            if(NSClassFromString(@"NSUserNotification"))
            {
                NSUserNotification *notification = [NSUserNotification new];
                notification.hasActionButton = NO;
                notification.title = title;
                notification.informativeText = description;
                [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
            }
            else
            {
                [GrowlApplicationBridge notifyWithTitle:title
                                            description:description
                                       notificationName:notificationName
                                               iconData:self.originalDockImageData
                                               priority:0
                                               isSticky:FALSE
                                           clickContext:nil];
            }
        }
        
		return;
	}
	
	BOOL shouldZip = ([filenames count] > 1);
	if(!shouldZip && [filenames count] == 1) {
		BOOL isDirectory;
		[[NSFileManager defaultManager] fileExistsAtPath:[filenames objectAtIndex:0]
                                         isDirectory:&isDirectory];
		shouldZip = isDirectory;
	}
	
	NSString *file = nil;
	if(shouldZip) {
		file = [self.zipFiles zipFiles:filenames];
		deleteFile = YES;
	}
	else if([filenames count] == 1) {
		file = [filenames objectAtIndex:0];
	}
	
	NSMutableString *randStr = [NSMutableString string];
	for(int i = 0; i < 10; i++) {
		int r = arc4random() % 62;
		if(r <= 9)
			[randStr appendFormat:@"%i",r];
		else if(r <= 35)
			[randStr appendFormat:@"%c",(r - 10) + 65];
		else
			[randStr appendFormat:@"%c",(r - 36) + 97];
	}
	
	NSString *filename;
   
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"use_filename"]) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"use_hash"]) {
            filename = [[file lastPathComponent] stringByDeletingPathExtension];
            filename = [filename stringByAppendingFormat:@"-%@",randStr];
            filename = [filename stringByAppendingPathExtension:[file pathExtension]];
        }
        else {
            filename = [[file lastPathComponent] stringByDeletingPathExtension];
            filename = [filename stringByAppendingPathExtension:[file pathExtension]];
        }
    }
    else {
        filename = randStr;
        filename = [filename stringByAppendingPathExtension:[file pathExtension]];
        }

 
	if(file)
		[self.fileUploader uploadFile:file
                       toFilename:filename
                       deleteFile:deleteFile];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setDisplayStatusItem:(BOOL)flag
{
	if(flag) {
		if(!self.statusItem) {
			self.statusItem = [[NSStatusBar systemStatusBar]
                         statusItemWithLength:NSVariableStatusItemLength];
			self.statusItem.menu = self.statusMenu;
			self.statusItem.highlightMode = YES;
			
			self.statusView = [[[MVStatusItemView alloc] initWithFrame:NSMakeRect(0, 0, 26, 24)]
                         autorelease];
			self.statusView.statusItem = self.statusItem;
			self.statusView.menu = self.statusMenu;
			self.statusView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
			self.statusView.image = [NSImage imageNamed:@"status_item"];
			self.statusView.alternateImage = [NSImage imageNamed:@"status_item_highlighted"];
			self.statusView.errorImage = [NSImage imageNamed:@"status_item_error"];
			self.statusView.completedImage = [NSImage imageNamed:@"status_item_completed"];
			self.statusView.maskImage = [NSImage imageNamed:@"status_item_mask"];
			self.statusView.emptyImage = [NSImage imageNamed:@"status_item_empty"];
			self.statusView.delegate = self;
			
			self.statusItem.view = self.statusView;
		}
	}
	else {
		if(self.statusItem)
			[[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
		self.statusItem = nil;
		self.statusView = nil;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setRegisterClipboardShortcut:(BOOL)flag
                            keyCombo:(KeyCombo)keyCombo
{
	DDHotKeyCenter * hotKeyCenter = [[DDHotKeyCenter alloc] init];
	
	if(self.isRegisteredClipboardShortcut) {
		[hotKeyCenter unregisterHotKeyWithKeyCode:self.registeredClipboardShortcut.code
                                modifierFlags:self.registeredClipboardShortcut.flags];
	}
	self.isRegisteredClipboardShortcut = NO;
	
	if(flag) {
		if (![hotKeyCenter registerHotKeyWithKeyCode:keyCombo.code
                                   modifierFlags:keyCombo.flags
                                          target:self
                                          action:@selector(uploadClipboardFromShortcut:)
                                          object:nil])
			NSLog(@"Failed to register clipboard shortcut");
		else {
			self.registeredClipboardShortcut = keyCombo;
			self.isRegisteredClipboardShortcut = YES;
		}
	}
	[hotKeyCenter release];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadClipboardFromShortcut:(NSEvent *)event
{
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *types = [pasteboard types];
	if([types containsObject:NSFilenamesPboardType])
	{
		[self uploadFiles:[pasteboard filesRepresentation]];
	}
	else if([types containsObject:NSPasteboardTypePNG])
	{
		[self uploadPNG:[pasteboard dataForType:NSPasteboardTypePNG]];
	}
	else if([types containsObject:NSStringPboardType])
	{
		[self uploadString:[pasteboard stringForType:NSStringPboardType]];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)restoreDockIcon
{
	self.statusView.state = MVStatusItemStateNormal;
	self.statusView.progression = 0;
	
	if(self.showDockIcon) {
		self.dockImage.state = MVDockImageStateNormal;
		self.dockImage.progression = 0;
		[self updateDockIcon];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updateDockIcon
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApp setApplicationIconImage:self.dockImage];
	[pool release];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)displayCompletedIcons
{
	self.statusView.state = MVStatusItemStateComplete;
	
	if(self.showDockIcon) {
		self.dockImage.progression = 1;
		self.dockImage.state = MVDockImageStateComplete;
		[self updateDockIcon];
	}
	
	if(self.restoreDockIconTimer)
		[self.restoreDockIconTimer invalidate];
	self.restoreDockIconTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                               target:self
                                                             selector:@selector(restoreDockIcon)
                                                             userInfo:nil
                                                              repeats:NO];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)copyURLFromMenuItem:(NSMenuItem*)menuItem
{
	NSString *url = menuItem.toolTip;
	NSString *type = NSStringPboardType;
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:type] owner:nil];
	[[NSPasteboard generalPasteboard] setString:url forType:type];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"growl"])
    {
        NSString *title = @"Paste it!";
        NSString *description = @"The URL has been written into your pasteboard";
        NSString *notificationName = @"URL copied";
        
        if(NSClassFromString(@"NSUserNotification"))
        {
            NSUserNotification *notification = [NSUserNotification new];
            notification.hasActionButton = NO;
            notification.title = title;
            notification.informativeText = description;
            [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        }
        else
        {
            [GrowlApplicationBridge notifyWithTitle:title
                                        description:description
                                   notificationName:notificationName
                                           iconData:self.originalDockImageData
                                           priority:0
                                           isSticky:FALSE
                                       clickContext:nil];
        }
    }
	
	[self displayCompletedIcons];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSWindow Notification methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)windowDidUpdate:(NSNotification*)notification
{
//	if(self.statusItem && self.statusItem.view.window)
//		[self.statusItem.view.window makeKeyAndOrderFront:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark DirectoryListenerDelegate methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)directoryListener:(MVScreenshotsListener *)aDirectoryListener
                  newFile:(NSURL *)fileURL
{
	BOOL deleteScreenshots = [[NSUserDefaults standardUserDefaults] boolForKey:@"delete_screenshots"];
	[self uploadFiles:[NSArray arrayWithObject:fileURL.path] deleteFile:deleteScreenshots];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVFileUploaderDelegate methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploader:(MVFileUploader *)fileUploader
    didFailWithError:(NSString *)error
{
	self.statusView.state = MVStatusItemStateError;
	if(self.showDockIcon) {
		self.dockImage.state = MVDockImageStateError;
		self.dockImage.progression = 1.0;
		[self updateDockIcon];
	}
  
	
	if(self.restoreDockIconTimer)
		[self.restoreDockIconTimer invalidate];
	self.restoreDockIconTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                               target:self
                                                             selector:@selector(restoreDockIcon)
                                                             userInfo:nil
                                                              repeats:NO];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"growl"])
    {
        NSString *title = @"Upload failed";
        NSString *description = @"Please check your connection configuration and internet connection.";
        NSString *notificationName = @"Bad configuration";
        
        if(NSClassFromString(@"NSUserNotification"))
        {
            NSUserNotification *notification = [NSUserNotification new];
            notification.hasActionButton = NO;
            notification.title = title;
            notification.informativeText = description;
            [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        }
        else
        {
            [GrowlApplicationBridge notifyWithTitle:title
                                        description:description
                                   notificationName:notificationName
                                           iconData:self.originalDockImageData
                                           priority:0
                                           isSticky:FALSE
                                       clickContext:nil];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploaderDidStart:(MVFileUploader*)fileUploader
{
	self.statusView.state = MVStatusItemStateUploading;
	self.statusView.progression = 0;
	
	if(self.restoreDockIconTimer)
		[self.restoreDockIconTimer invalidate];
	if(self.showDockIcon) {
		self.dockImage.state = MVDockImageStateUploading;
		[self updateDockIcon];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploader:(MVFileUploader*)fileUploader
didChangeProgression:(float)progression
{
	self.statusView.state = MVStatusItemStateUploading;
	self.statusView.progression = progression;
	
	if(self.showDockIcon) {
		if(fabs(self.dockImage.progression - progression) > 0.01) {
			self.dockImage.state = MVDockImageStateUploading;
			self.dockImage.progression = progression;
			[self updateDockIcon];
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploader:(MVFileUploader*)fileUploader
          didSuccess:(NSString*)url
            fileName:(NSString*)filename
            filePath:(NSString*)filepath
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if([defaults boolForKey:@"url_shortener"]) {
		NSString *tmpUrl = [self.urlShortener shortenURL:url];
		if(tmpUrl)
			url = tmpUrl;
	}
	
	NSString *type = NSStringPboardType;
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:type] owner:nil];
	[[NSPasteboard generalPasteboard] setString:url forType:type];
  
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[filepath lastPathComponent]
                                                    action:@selector(copyURLFromMenuItem:)
                                             keyEquivalent:@""];
	[menuItem setToolTip:url];
	[self.lastUploadedFilesMenuItems insertObject:menuItem 
                                        atIndex:0];
	[menuItem release];
	
	if(self.separatorMenuItem.menu != self.statusMenu)
		[self.statusMenu insertItem:self.separatorMenuItem 
                        atIndex:0];
	[self.statusMenu insertItem:menuItem atIndex:0];
	while([self.lastUploadedFilesMenuItems count] > 5) {
		menuItem = [self.lastUploadedFilesMenuItems lastObject];
		[self.statusMenu removeItem:menuItem];
		[self.lastUploadedFilesMenuItems removeObjectAtIndex:
     [self.lastUploadedFilesMenuItems count] - 1];
	}
	
	self.dockImage.state = MVDockImageStateNormal;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"growl"])
    {
        NSString *title = @"File uploaded";
        NSString *description = @"The URL has been written into your pasteboard";
        NSString *notificationName = @"File uploaded";
        
        if(NSClassFromString(@"NSUserNotification"))
        {
            NSUserNotification *notification = [NSUserNotification new];
            notification.hasActionButton = NO;
            notification.title = title;
            notification.informativeText = description;
            [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
        }
        else
        {
            [GrowlApplicationBridge notifyWithTitle:title
                                        description:description
                                   notificationName:notificationName
                                           iconData:self.originalDockImageData
                                           priority:0
                                           isSticky:FALSE
                                       clickContext:nil];
        }
    }
  
	[self displayCompletedIcons];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVStatusItemViewDelegate Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)statusItemView:(MVStatusItemView *)view 
          didDropFiles:(NSArray *)filenames
{
	[self uploadFiles:filenames];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)statusItemView:(MVStatusItemView*)view
         didDropString:(NSString*)string
{
	[self uploadString:string];
}

@end
