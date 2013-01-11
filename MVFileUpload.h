//
//  MVFileUpload.h
//  FileShuttle
//
//  Created by Michael Villar on 12/10/11.
//

#import <Foundation/Foundation.h>
#import "MVFileUploadDelegate.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFileUpload : NSObject {
	NSString *destination_;
	NSString *username_;
	NSString *password_;
	NSURL *source_;
	NSObject <MVFileUploadDelegate> *delegate_;
}

@property (retain) NSString *destination;
@property (retain) NSString *username;
@property (retain) NSString *password;
@property (retain) NSURL *source;
@property (assign) NSObject <MVFileUploadDelegate> *delegate;

- (id)initWithDestination:(NSString *)destination
                 username:(NSString *)username
                 password:(NSString *)password
                   source:(NSURL *)source
                 delegate:(NSObject <MVFileUploadDelegate> *)delegate;
- (void)start;
- (void)cancel;

@end
