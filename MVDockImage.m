//
//  MVDockImage.m
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import "MVDockImage.h"

int const MVDockImageStateNormal = 0;
int const MVDockImageStateUploading = 1;
int const MVDockImageStateComplete = 2;
int const MVDockImageStateError = 3;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVDockImage ()
- (void)display;
@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVDockImage

@synthesize state;
@synthesize progression;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init
{
  self = [super initWithSize:NSMakeSize(512, 512)];
  if (self) {
		appIcon = [NSImage imageNamed:@"fileshuttle.icns"];
		progression = 0;
		state = MVDockImageStateNormal;
		[self display];
  }
  
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setState:(int)aState {
	if(state == aState)
		return;
	state = aState;
	[self display];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setProgression:(float)aProgression {
	if(progression == aProgression)
		return;
	progression = aProgression;
	[self display];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)display {
	[self lockFocus];
	
	[[NSColor clearColor] set];
	
	NSRect bounds = NSMakeRect(0,0,[self size].width, [self size].height);
	NSRectFill(bounds);
	
	NSImageRep *representation = [appIcon bestRepresentationForRect:bounds
                                                          context:[NSGraphicsContext currentContext]
                                                            hints:nil];
  
	[appIcon drawRepresentation:representation inRect:bounds];
	
	if(progression >= 0 && state != MVDockImageStateNormal) {
		CGFloat top = 50.0;
		CGFloat height = 60.0;
		CGFloat margin = 20.0;
		CGFloat width = progression * (512 - 2 * margin);
		CGFloat radius = 36.0;
		
		NSBezierPath* backProgressBar = [NSBezierPath bezierPath];
		NSRect roundedRect = NSMakeRect(margin, top, (512 - 2 * margin), height);
		[backProgressBar appendBezierPathWithRoundedRect:roundedRect
                                        cornerRadius:radius];
		[backProgressBar closePath];
		[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5]set];
		[backProgressBar fill];
		
		
		NSBezierPath* progressBar = [NSBezierPath bezierPath];
		[progressBar appendBezierPathWithRoundedRect:NSMakeRect(margin, top, width, height)
                                    cornerRadius:radius];
		[progressBar closePath];
		
		if(state == MVDockImageStateUploading)
			[[NSColor whiteColor] set];
		else if(state == MVDockImageStateComplete)
			[[NSColor colorWithCalibratedRed:197.0/255.0 green:255.0/255.0 blue:72.0/255.0 alpha:1.0] set];
		else if(state == MVDockImageStateError)
			[[NSColor redColor] set];
		
		[progressBar fill];
	}
	
	[self unlockFocus];
}

@end
