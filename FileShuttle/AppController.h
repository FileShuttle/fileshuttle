//
//  AppController.h
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import <Foundation/Foundation.h>
#import <Growl/Growl.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "DDHotKeyCenter.h"
#import "MVDockImage.h"
#import "MVScreenshotsListener.h"
#import "MVFileUploader.h"
#import "MVURLShortener.h"
#import "MVZipFiles.h"
#import "MVStatusItemView.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface AppController : NSObject <NSApplicationDelegate,
                                     MVDirectoryListenerDelegate,
                                     MVFileUploaderDelegate,
                                     MVStatusItemViewDelegate>
{
	MVDockImage *dockImage_;
	MVScreenshotsListener *screenshotsDirectoryListener_;
	MVFileUploader *fileUploader_;
	NSTimer *restoreDockIconTimer_;
	NSStatusItem *statusItem_;
	MVStatusItemView *statusView_;
	NSMenu *statusMenu_;
	MVURLShortener *urlShortener_;
	MVZipFiles *zipFiles_;
	BOOL showDockIcon_;
	NSMutableArray *lastUploadedFilesMenuItems_;
	NSMenuItem *separatorMenuItem_;
	NSData *originalDockImageData_;
	KeyCombo registeredClipboardShortcut_;
	BOOL isRegisteredClipboardShortcut_;
	NSWindow *preferencesWindow_;
}

@property (assign) IBOutlet NSWindow *preferencesWindow;

@end
