//
//  MVFileUploadDelegate.h
//  FileShuttle
//
//  Created by Michael Villar on 12/10/11.
//

#import <Foundation/Foundation.h>

@class MVFileUpload;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol MVFileUploadDelegate <NSObject>

@optional
- (void)fileUpload:(MVFileUpload*)fileUpload didFailWithError:(NSString*)error;
- (void)fileUploadDidSuccess:(MVFileUpload*)fileUpload;
- (void)fileUploadDidStartUpload:(MVFileUpload*)fileUpload;
- (void)fileUpload:(MVFileUpload*)fileUpload didChangeProgression:(float)progression
         bytesRead:(long)bytesRead
        totalBytes:(long)totalBytes;

@end
