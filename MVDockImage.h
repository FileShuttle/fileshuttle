//
//  MVDockImage.h
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import <Foundation/Foundation.h>
#import "NSBezierPath-RoundedRect.h"

extern int const MVDockImageStateNormal;
extern int const MVDockImageStateUploading;
extern int const MVDockImageStateComplete;
extern int const MVDockImageStateError;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVDockImage : NSImage {
	
@private
	int state;
	float progression;
  NSImage *appIcon;
}

@property (assign, nonatomic) int state;
@property (assign, nonatomic) float progression;

@end
