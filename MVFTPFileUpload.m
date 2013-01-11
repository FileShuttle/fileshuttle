//
//  MVFTPFileUpload.m
//  FileShuttle
//
//  Created by Michael Villar on 12/10/11.
//

#import "MVFTPFileUpload.h"

static const CFOptionFlags kNetworkEvents =
kCFStreamEventOpenCompleted
| kCFStreamEventHasBytesAvailable
| kCFStreamEventEndEncountered
| kCFStreamEventCanAcceptBytes
| kCFStreamEventErrorOccurred;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFTPFileUpload ()

@property (assign) CFWriteStreamRef writeStream;
@property (assign) CFReadStreamRef readStream;
@property (assign) long fileSize;
@property (assign) long totalBytesWritten;
@property (assign) long leftOverByteCount;

- (void)uploadCallback:(CFWriteStreamRef)writeStream
                  type:(CFStreamEventType)type;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
static void MVFTPFileUploadCallback(CFWriteStreamRef writeStream,
                                    CFStreamEventType type,
                                    void * clientCallBackInfo)
{
	MVFTPFileUpload *fileUpload = (MVFTPFileUpload*)clientCallBackInfo;
	[fileUpload uploadCallback:writeStream
                        type:type];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVFTPFileUpload

@synthesize writeStream       = writeStream_,
            readStream        = readStream_,
            fileSize          = fileSize_,
            totalBytesWritten	= totalBytesWritten_,
            leftOverByteCount	= leftOverByteCount_;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Memory management

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
	[self cancel];
	
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
	if (self.readStream) {
    CFReadStreamUnscheduleFromRunLoop(self.readStream,
                                      CFRunLoopGetCurrent(),
                                      kCFRunLoopCommonModes);
    (void) CFReadStreamSetClient(self.readStream, kCFStreamEventNone, NULL, NULL);
    
    CFReadStreamClose(self.readStream);
    CFRelease(self.readStream);
		readStream_ = NULL;
  }
	
  if (self.writeStream) {
    CFWriteStreamUnscheduleFromRunLoop(self.writeStream,
                                       CFRunLoopGetCurrent(),
                                       kCFRunLoopCommonModes);
    (void) CFWriteStreamSetClient(self.writeStream, kCFStreamEventNone, NULL, NULL);
    
    CFWriteStreamClose(self.writeStream);
    CFRelease(self.writeStream);
		writeStream_ = NULL;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)start {
	NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.source path]
                                                                         error:nil];
	if(attrs) {
		self.fileSize = [((NSNumber*)[attrs valueForKey:NSFileSize]) longValue];
	}
	
  CFStreamClientContext  context = { 0, NULL, NULL, NULL, NULL };
  context.info = (void *)self;
  
  Boolean success = true;
	
	self.readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (CFURLRef)self.source);
	
	CFURLRef destination = (CFURLRef)[NSURL URLWithString:self.destination];
  self.writeStream = CFWriteStreamCreateWithFTPURL(kCFAllocatorDefault, destination);
	
  success = CFReadStreamOpen(self.readStream);
  if (success)
	{
    success = CFWriteStreamSetClient(self.writeStream,
                                     kNetworkEvents,
                                     MVFTPFileUploadCallback,
                                     &context);
    if (success)
		{
      CFWriteStreamScheduleWithRunLoop(self.writeStream,
                                       CFRunLoopGetCurrent(),
                                       kCFRunLoopCommonModes);
      
			if (self.username)
			{
				success = CFWriteStreamSetProperty((CFWriteStreamRef)self.writeStream,
                                           kCFStreamPropertyFTPUserName,
                                           (CFStringRef)self.username);
				if (self.password)
				{
					success = CFWriteStreamSetProperty((CFWriteStreamRef)self.writeStream,
                                             kCFStreamPropertyFTPPassword,
                                             (CFStringRef)self.password);
				}
			}
			
      //			success = CFWriteStreamSetProperty((CFWriteStreamRef)self.writeStream,
      //											   kCFStreamPropertyFTPAttemptPersistentConnection,
      //											   kCFBooleanTrue);
			
			success = CFWriteStreamOpen(self.writeStream);
      if (success == false) {
				if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
					[self.delegate fileUpload:self
                   didFailWithError:@"CFWriteStreamOpen failed"];
      }
			else {
				if([self.delegate respondsToSelector:@selector(fileUploadDidStartUpload:)])
					[self.delegate fileUploadDidStartUpload:self];
			}
    } else {
			if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
				[self.delegate fileUpload:self
                 didFailWithError:@"CFWriteStreamSetClient failed"];
      fprintf(stderr, "CFWriteStreamSetClient failed\n");
    }
  } else {
		if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
			[self.delegate fileUpload:self
               didFailWithError:@"CFReadStreamOpen failed"];
    fprintf(stderr, "CFReadStreamOpen failed\n");
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadCallback:(CFWriteStreamRef)writeStream
                  type:(CFStreamEventType)type
{
  CFIndex          bytesRead;
  CFIndex          bytesAvailable;
  CFIndex          bytesWritten;
  CFStreamError    error;
  
  switch (type) {
    case kCFStreamEventOpenCompleted:
      break;
    case kCFStreamEventCanAcceptBytes:
      if (self.leftOverByteCount > 0) {
        bytesRead = 0;
        bytesAvailable = self.leftOverByteCount;
      } else {
        bytesRead = CFReadStreamRead(self.readStream, buffer, kMyBufferSize);
        if (bytesRead < 0) {
					if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
						[self.delegate fileUpload:self
                     didFailWithError:@"CFReadStreamRead"];
          return;
        }
        bytesAvailable = bytesRead;
      }
      bytesWritten = 0;
      
      if (bytesAvailable == 0) {
        if([self.delegate respondsToSelector:@selector(fileUploadDidSuccess:)])
					[self.delegate fileUploadDidSuccess:self];
        return;
      } else {
        bytesWritten = CFWriteStreamWrite(self.writeStream, buffer, bytesAvailable);
        if (bytesWritten > 0) {
          self.totalBytesWritten += bytesWritten;
          if (bytesWritten < bytesAvailable) {
            self.leftOverByteCount = (UInt32)(bytesAvailable - bytesWritten);
            memmove(buffer, buffer + bytesWritten, self.leftOverByteCount);
          } else {
            self.leftOverByteCount = 0;
          }
        } else if (bytesWritten < 0) {
          if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
						[self.delegate fileUpload:self
                     didFailWithError:@"CFWriteStreamWrite"];
        }
      }
			if ((bytesRead > 0) || (bytesWritten > 0)) {
				float progression = ((float)self.totalBytesWritten / (float)self.fileSize);
				if([self.delegate respondsToSelector:
            @selector(fileUpload:didChangeProgression:bytesRead:totalBytes:)]) {
					[self.delegate fileUpload:self
               didChangeProgression:progression
                          bytesRead:self.totalBytesWritten
                         totalBytes:self.fileSize];
				}
      }
      break;
    case kCFStreamEventErrorOccurred:
      error = CFWriteStreamGetError(self.writeStream);
			if([self.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
				[self.delegate fileUpload:self 
                 didFailWithError:@"CFReadStreamGetError"];
	}
}

@end
