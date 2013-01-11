//
//  MVDirectoryListener.m
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import "MVDirectoryListener.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVDirectoryListener

@synthesize listening,
            path,
            extension,
            delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithPath:(NSString*)aPath
{
  self = [super init];
  if (self) {
		path = [aPath retain];
		date = [[NSDate alloc] init];
		extension = nil;
  }
  
  return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[path release];
	[date release];
	[extension release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setListening:(BOOL)isListening {
	if(listening == isListening)
		return;
	listening = isListening;
	NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
	if(listening) {
		[center addObserver:self
               selector:@selector(directoryNotification:)
                   name:@"com.apple.carbon.core.DirectoryNotification"
                 object:nil
		 suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	}
	else {
		[center removeObserver:self];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)directoryNotification:(NSNotification*)aNotification {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:nil];
	NSDate *newDate = nil;
	for (NSString *filename in files) {
		if (!extension || [[filename pathExtension] isEqualToString:extension]) {
			NSString *filepath = [path stringByAppendingPathComponent:filename];
			NSDictionary *filedict = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:nil];
			if(filedict != nil) {
				NSDate *creationDate = [filedict objectForKey:NSFileCreationDate];
				if(creationDate != nil && [date compare:creationDate] == NSOrderedAscending) {
					if(newDate == nil || ([newDate compare:creationDate] == NSOrderedAscending)) {
						newDate = creationDate;
					}
					
					if([delegate respondsToSelector:@selector(directoryListener:newFile:)])
						[delegate directoryListener:self newFile:filename];
				}
			}
		}
	}
	if(newDate) {
		[date release], date = nil;
		date = [newDate retain];
	}
}

@end
