//
//  NSPasteboard+Files.m
//  Kickoff
//
//  Created by Michael Villar on 7/6/11.
//

#import "NSPasteboard+Files.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSPasteboard (Files)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSArray*)filesRepresentation {
	NSString *type = [self availableTypeFromArray:
                    [NSArray arrayWithObjects:
                     NSFilenamesPboardType,NSTIFFPboardType,
                     NSPasteboardTypeTIFF,NSPasteboardTypePNG,nil]];
	NSMutableArray *files = [NSMutableArray array];
	if(!type)
		return files;
	NSData *data = [self dataForType:type];
	if(type == NSTIFFPboardType || type == NSPasteboardTypeTIFF || type == NSPasteboardTypePNG) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
		NSString *path = [NSString stringWithFormat:@"/tmp/image-%@.png",
                      [formatter stringFromDate:[NSDate date]]];
		[formatter release];
		
    NSData *imageRepresentation = [[NSBitmapImageRep imageRepWithData:data]
                                   representationUsingType:NSPNGFileType
                                   properties:nil];
		[imageRepresentation writeToFile:path atomically:YES];
		
		[files addObject:path];
	}
	else if(type == NSFilenamesPboardType) {
		NSString* errorDescription;
		files = [NSPropertyListSerialization propertyListFromData:data
												 mutabilityOption:kCFPropertyListImmutable
														   format:nil
												 errorDescription:&errorDescription];
	}
	
	if(!files)
		return [NSArray array];
	return files;
}

@end
