//
//  MVFileUploader.h
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import <Foundation/Foundation.h>
#import "MVFTPFileUpload.h"
#import "MVSFTPFileUpload.h"
#import "MVFileUpload.h"
#import "MVFileUploadDelegate.h"

@class MVFileUploader;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MVFileUploaderDelegate

- (void)fileUploaderDidStart:(MVFileUploader*)fileUploader;
- (void)fileUploader:(MVFileUploader*)fileUploader
didChangeProgression:(float)progression;
- (void)fileUploader:(MVFileUploader*)fileUploader
          didSuccess:(NSString*)url
            fileName:(NSString*)filename
            filePath:(NSString*)filepath;
- (void)fileUploader:(MVFileUploader *)fileUploader
    didFailWithError:(NSString*)error;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFileUploader : NSObject <MVFileUploadDelegate> {
	MVFileUpload *fileUpload_;
	NSString *filename_;
	NSString *filepath_;
	BOOL deleteFile_;
	int tries_;
	NSObject <MVFileUploaderDelegate> *delegate_;
}

@property (assign) NSObject <MVFileUploaderDelegate> *delegate;

- (void)uploadFile:(NSString*)filepath
        toFilename:(NSString*)filename
        deleteFile:(BOOL)deleteFile;

@end
