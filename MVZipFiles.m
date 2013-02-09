//
//  MVZipFiles.m
//  FileShuttle
//
//  Created by Michael Villar on 12/11/11.
//

#import "MVZipFiles.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVZipFiles

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)zipFiles:(NSArray*)filenames
{
	NSString *tmpDirectory = @"/tmp/fileshuttle_files/";
	BOOL isDirectory;
	if([[NSFileManager defaultManager] fileExistsAtPath:tmpDirectory
                                          isDirectory:&isDirectory])
	{
		[[NSFileManager defaultManager] removeItemAtPath:tmpDirectory error:nil];
	}
	[[NSFileManager defaultManager] createDirectoryAtPath:tmpDirectory
                            withIntermediateDirectories:YES
                                             attributes:nil
                                                  error:nil];
	
	NSString *path = @"/tmp/files.zip";
	if([[NSFileManager defaultManager] fileExistsAtPath:path])
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	
	NSTask *zipTask = [[NSTask alloc] init];
	[zipTask setCurrentDirectoryPath:tmpDirectory];
	[zipTask setLaunchPath:@"/usr/bin/zip"];
	
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"-q", @"-r", @"-b", @".",
                          path,
                          nil];
	
	NSString *file;
	for(file in filenames) {
		NSString *tmpFile = [NSString stringWithFormat:
                         @"%@%@",tmpDirectory,[file lastPathComponent]];
		[[NSFileManager defaultManager] createSymbolicLinkAtPath:tmpFile
                                         withDestinationPath:file
                                                       error:nil];
		[args addObject:[file lastPathComponent]];
	}
	
	[zipTask setArguments:args];
	
	// launch it and wait for execution
	[zipTask launch];
	[zipTask waitUntilExit];
	
	// handle the task's termination status
	if ([zipTask terminationStatus] == 0) {
		[zipTask release];
        NSDictionary *attributes=[NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0644] forKey:NSFilePosixPermissions];
        [[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:path error:nil];
		return path;
	}
	[zipTask release];
	return nil;
}

@end
