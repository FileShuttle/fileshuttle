//
//  CURLFTPSession.h
//  CURLHandle
//
//  Created by Mike Abdullah on 04/03/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <CURLHandle/CURLHandle.h>


@protocol CURLFTPSessionDelegate;


@interface CURLFTPSession : NSObject <CURLHandleDelegate>
{
  @private
    CURLHandle          *_handle;
    NSURLRequest        *_request;
    NSURLCredential     *_credential;
    
    id <CURLFTPSessionDelegate> _delegate;
    
    NSMutableData   *_data;
    void            (^_progressBlock)(NSUInteger bytesWritten);
}

// Returns nil if not a supported FTP URL
// All paths passed to a session are resolved relative to this request's URL. Normally you pass in a URL like ftp://example.com/ so it doesn't really make a difference! But let's say you passed in ftp://example.com/foo/ , a path of @"bar.html" would end up working on the file at ftp://example.com/foo/bar.html (i.e. the path foo/bar.html from the user's home directory)
- (id)initWithRequest:(NSURLRequest *)request;
@property(nonatomic, copy) NSURLRequest *baseRequest;   // throws exception if not FTP URL

- (void)useCredential:(NSURLCredential *)credential;

// Note that it's possible for this method to return nil with an error of nil, although I don't know what circumstances could cause this
- (NSString *)homeDirectoryPath:(NSError **)error;


#pragma mark Discovering Directory Contents

// Potentially, directory listings arrive in pieces. As the listing is parsed, each resource is passed to the block as dictionary with keys such as kCFFTPResourceName
- (BOOL)enumerateContentsOfDirectoryAtPath:(NSString *)path
                                     error:(NSError **)error
                                usingBlock:(void (^)(NSDictionary *parsedResourceListing))block;


#pragma mark Creating and Deleting Items

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error;

#if NS_BLOCKS_AVAILABLE
- (BOOL)createFileAtPath:(NSString *)path withContentsOfURL:(NSURL *)url withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error progressBlock:(void (^)(NSUInteger bytesWritten))progressBlock;
#endif

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates error:(NSError **)error;

- (BOOL)removeFileAtPath:(NSString *)path error:(NSError **)error;


#pragma mark Setting Attributes
// Only NSFilePosixPermissions is recognised at present. Note that some servers don't support this so will return an error (code 500)
// All other attributes are ignored
- (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error;


#pragma mark Cancellation
// Can call on any thread to cancel the current operation as soon as reasonable
- (void)cancel;


#pragma mark Delegate
@property(nonatomic, assign) id <CURLFTPSessionDelegate> delegate;


#pragma mark FTP URLs
+ (NSURL *)URLWithPath:(NSString *)path relativeToURL:(NSURL *)baseURL;
+ (NSString *)pathOfURLRelativeToHomeDirectory:(NSURL *)URL;


@end


@protocol CURLFTPSessionDelegate <NSObject>
- (void)FTPSession:(CURLFTPSession *)session didReceiveDebugInfo:(NSString *)info ofType:(curl_infotype)type;
@end