//
//  MVPreferencesController.h
//  FileShuttle
//
//  Created by Michael Villar on 8/15/11.
//

#import <Foundation/Foundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVPreferencesController : NSObject <NSTextFieldDelegate> {
	BOOL showDockIcon_;
	NSTimer *passwordTimer_;
	NSWindow *window_;
	NSSecureTextField *passwordTextField_;
	NSPopUpButton *showInPopUpButton_;
	SRRecorderControl *clipboardRecorderControl_;
    NSPopUpButton *setFilenamePopUpButton;
    NSPopUpButton *shortenerSelectionPopUpButton;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSToolbar *toolbar;
@property (assign) IBOutlet NSView *generalView;
@property (assign) IBOutlet NSView *connectionView;
@property (assign) IBOutlet NSView *urlshorteningView;
@property (assign) IBOutlet NSSecureTextField *passwordTextField;
@property (assign) IBOutlet NSPopUpButton *showInPopUpButton;
@property (assign) IBOutlet NSPopUpButton *setFilenamePopUpButton;
@property (assign) IBOutlet NSButton *changePermissionsCheckbox;
@property (assign) IBOutlet NSTextField *permissionsTextField;
@property (assign) IBOutlet SRRecorderControl *clipboardRecorderControl;
@property (assign) IBOutlet NSButton *enableShortenerCheckbox;
@property (assign) IBOutlet NSPopUpButton *shortenerSelectionPopUpButton;
@property (assign) IBOutlet NSTextField *shortenerApiTokenField;

- (IBAction)toolbarItemAction:(id)sender;
- (IBAction)protocolChanged:(id)sender;
- (IBAction)passwordChanged:(id)sender;
- (IBAction)showInPopUpButtonChanged:(id)sender;
- (IBAction)setFilenamePopUpButtonChanged:(id)sender;
- (IBAction)changePermissionsCheckboxChanged:(id)sender;
- (IBAction)shortenerSelectionPopUpButtonChanged:(id)sender;
- (IBAction)shortenerApiTokenChanged:(id)sender;
- (IBAction)enableShortenerCheckboxChanged:(id)sender;

@end
