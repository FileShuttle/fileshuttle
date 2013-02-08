//
//  MVFTPFileUpload.m
//  FileShuttle
//
//  Created by Michael Villar on 12/10/11.
//

#import "MVFTPFileUpload.h"
#import <CURLHandle/CURLFTPSession.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFTPFileUpload ()

@property (assign) long fileSize;
@property (assign) long totalBytesWritten;
@property (strong, readwrite) CURLFTPSession *ftpSession;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVFTPFileUpload

@synthesize fileSize          = fileSize_,
            totalBytesWritten	= totalBytesWritten_,
            ftpSession        = ftpSession_;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
  [self.ftpSession cancel];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)start {
  NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.source path]
                                                                         error:nil];
  if(attrs) {
    self.fileSize = [((NSNumber*)[attrs valueForKey:NSFileSize]) longValue];
  }
  
  NSURL *destination = [NSURL URLWithString:self.destination];
  NSURLRequest *ftpReq = [NSURLRequest requestWithURL:destination
                                          cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                      timeoutInterval:20];
  self.ftpSession = [[CURLFTPSession alloc] initWithRequest:ftpReq];
  NSURLCredential *credential = [[NSURLCredential alloc] initWithUser:self.username
                                                             password:self.password
                                                          persistence:NSURLCredentialPersistenceNone];
  [self.ftpSession useCredential:credential];
  
  if([self.delegate respondsToSelector:@selector(fileUploadDidStartUpload:)])
    [self.delegate fileUploadDidStartUpload:self];

  __block __weak MVFTPFileUpload *weakSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSError *error = nil;
    [weakSelf.ftpSession createFileAtPath:destination.path
                        withContentsOfURL:weakSelf.source
              withIntermediateDirectories:YES
                                    error:&error
                            progressBlock:^(NSUInteger bytesWritten)
     {
       weakSelf.totalBytesWritten += bytesWritten;
       dispatch_async(dispatch_get_main_queue(), ^{
         float progression = ((float)weakSelf.totalBytesWritten / (float)weakSelf.fileSize);
         if([weakSelf.delegate respondsToSelector:
             @selector(fileUpload:didChangeProgression:bytesRead:totalBytes:)]) {
           [weakSelf.delegate fileUpload:weakSelf
                didChangeProgression:progression
                           bytesRead:weakSelf.totalBytesWritten
                          totalBytes:weakSelf.fileSize];
         }
       });
     }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      if(!error) {
        if([weakSelf.delegate respondsToSelector:@selector(fileUploadDidSuccess:)])
          [weakSelf.delegate fileUploadDidSuccess:self];
      }
      else {
        NSLog(@"Upload Failed with error %@",error);
        if([weakSelf.delegate respondsToSelector:@selector(fileUpload:didFailWithError:)])
          [weakSelf.delegate fileUpload:self
                       didFailWithError:error.description];
      }
    });
  });
}

@end
