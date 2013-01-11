//
//  MVStatusItemView.m
//  FileShuttle
//
//  Created by Michael Villar on 12/11/11.
//

#import "MVStatusItemView.h"
#import "NSPasteboard+Files.h"

int const MVStatusItemStateNormal = 0;
int const MVStatusItemStateUploading = 1;
int const MVStatusItemStateComplete = 2;
int const MVStatusItemStateError = 3;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVStatusItemView ()

@property (assign) BOOL isMenuVisible;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVStatusItemView

@synthesize statusItem        = statusItem_,
            image             = image_,
            emptyImage        = emptyImage_,
            maskImage         = maskImage_,
            alternateImage    = alternateImage_,
            errorImage        = errorImage_,
            completedImage    = completedImage_,
            state             = state_,
            progression       = progression_,
            isMenuVisible     = isMenuVisible_,
            delegate          = delegate_;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
	[statusItem_ release];
	[image_ release];
	[emptyImage_ release];
	[maskImage_ release];
	[alternateImage_ release];
	[errorImage_ release];
	[completedImage_ release];
	
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if(self) {
		statusItem_ = nil;
		image_ = nil;
		emptyImage_ = nil;
		maskImage_ = nil;
		state_ = MVStatusItemStateNormal;
		progression_ = 1.0;
		alternateImage_ = nil;
		errorImage_ = nil;
		completedImage_ = nil;
		delegate_ = nil;
		
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,
                                   NSStringPboardType,
                                   nil]];
    
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)mouseDown:(NSEvent *)event {
  [[self menu] setDelegate:self];
  [self.statusItem popUpStatusItemMenu:[self menu]];
  [self setNeedsDisplay:YES];
	[self.statusItem setHighlightMode:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)rightMouseDown:(NSEvent *)event {
  [self mouseDown:event];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)menuWillOpen:(NSMenu *)menu {
  self.isMenuVisible = YES;
  [self setNeedsDisplay:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)menuDidClose:(NSMenu *)menu {
  self.isMenuVisible = NO;
  [menu setDelegate:nil];
  [self setNeedsDisplay:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)drawRect:(NSRect)dirtyRect {
	[self.statusItem drawStatusBarBackgroundInRect:[self bounds]
                                   withHighlight:self.isMenuVisible];
	
	NSImage *image = nil;
	if(self.isMenuVisible && self.alternateImage)
		image = self.alternateImage;
	else {
		if(self.state == MVStatusItemStateNormal)
			image = self.image;
		else if(self.state == MVStatusItemStateComplete)
			image = self.completedImage;
		else if(self.state == MVStatusItemStateError)
			image = self.errorImage;
		else if(self.state == MVStatusItemStateUploading)
			image = self.emptyImage;
	}
	if(image)
	{
		[image drawInRect:NSMakeRect(2, 2, image.size.width, image.size.height)
             fromRect:NSMakeRect(0, 0, image.size.width, image.size.height)
            operation:NSCompositeSourceOver
             fraction:1.0];
		if(self.state == MVStatusItemStateUploading && image != self.alternateImage)
		{
			NSBezierPath *mask = [[NSBezierPath alloc] init];
			[mask appendBezierPathWithRect:NSMakeRect(0, 0, 6 + (self.progression * 12), image.size.height)];
			[mask addClip];
			
			[self.maskImage drawInRect:NSMakeRect(2, 2, image.size.width, image.size.height)
                        fromRect:NSMakeRect(0, 0, image.size.width, image.size.height)
                       operation:NSCompositeSourceOver
                        fraction:1.0];
      
			[mask release];
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setProgression:(float)progression
{
	if(progression == progression_)
		return;
	progression_ = progression;
	[self setNeedsDisplay:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setState:(int)state
{
	if(state == state_)
		return;
	state_ = state;
	[self setNeedsDisplay:YES];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Drag and drop

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
	return NSDragOperationCopy;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
	return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender
{
	NSPasteboard *pasteboard = sender.draggingPasteboard;
	NSArray *types = [pasteboard types];
	if([types containsObject:NSStringPboardType])
	{
		NSString *pboardString = [pasteboard stringForType:NSStringPboardType];
		if([self.delegate respondsToSelector:@selector(statusItemView:didDropString:)]) {
			[self.delegate statusItemView:self
                      didDropString:pboardString];
		}
	}
	else if([types containsObject:NSFilenamesPboardType])
	{
		if([self.delegate respondsToSelector:@selector(statusItemView:didDropFiles:)]) {
			[self.delegate statusItemView:self
                       didDropFiles:[pasteboard filesRepresentation]];
		}
	}
	return YES;
}

@end
