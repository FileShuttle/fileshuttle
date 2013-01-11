//
//  MVStatusItemView.h
//  FileShuttle
//
//  Created by Michael Villar on 12/11/11.
//

#import <Cocoa/Cocoa.h>

extern int const MVStatusItemStateNormal;
extern int const MVStatusItemStateUploading;
extern int const MVStatusItemStateComplete;
extern int const MVStatusItemStateError;

@class MVStatusItemView;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MVStatusItemViewDelegate

@optional;
- (void)statusItemView:(MVStatusItemView*)view
          didDropFiles:(NSArray*)filenames;
- (void)statusItemView:(MVStatusItemView*)view
         didDropString:(NSString*)string;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVStatusItemView : NSView <NSMenuDelegate> {
	BOOL isMenuVisible_;
	NSStatusItem *statusItem_;
	NSImage *image_;
	NSImage *emptyImage_;
	NSImage *maskImage_;
	NSImage *alternateImage_;
	NSImage *errorImage_;
	NSImage *completedImage_;
	int state_;
	float progression_;
	NSObject <MVStatusItemViewDelegate> *delegate_;
}

@property (retain) NSStatusItem *statusItem;
@property (retain, nonatomic) NSImage *image;
@property (retain, nonatomic) NSImage *emptyImage;
@property (retain, nonatomic) NSImage *maskImage;
@property (retain, nonatomic) NSImage *alternateImage;
@property (retain, nonatomic) NSImage *errorImage;
@property (retain, nonatomic) NSImage *completedImage;
@property (assign, nonatomic) int state;
@property (assign, nonatomic) float progression;
@property (assign) NSObject <MVStatusItemViewDelegate> *delegate;

@end
