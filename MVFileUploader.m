//
//  MVFileUploader.m
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import "MVFileUploader.h"
#import "AHKeychain.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@interface MVFileUploader ()

@property (retain) MVFileUpload *fileUpload;
@property (retain) NSString *filename;
@property (retain) NSString *filepath;
@property (assign) BOOL deleteFile;
@property (assign) int tries;

- (void)deleteFile:(NSURL*)fileURL;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVFileUploader

@synthesize delegate        = delegate_,
            fileUpload			= fileUpload_,
            filename        = filename_,
            filepath        = filepath_,
            deleteFile			= deleteFile_,
            tries           = tries_;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Memory Management

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
	[fileUpload_ release];
	[filename_ release];
	[filepath_ release];
	
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)init {
	self = [super init];
	if(self) {
		fileUpload_ = nil;
		filename_ = nil;
		filepath_ = nil;
		deleteFile_ = NO;
		tries_ = -1;
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)deleteFile:(NSURL*)fileURL
{
	if(!self.deleteFile)
		return;
	[[NSFileManager defaultManager] removeItemAtURL:fileURL
                                            error:nil];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)uploadFile:(NSString*)filepath
        toFilename:(NSString*)filename
        deleteFile:(BOOL)deleteFile
{
	if(self.fileUpload)
		return;
	self.tries = 3;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSURL *source = [NSURL fileURLWithPath:filepath];
	self.filepath = filepath;
	self.filename = filename;
	NSString *encodedFilename = [self.filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableString *path = [NSMutableString string];
	NSString *defaultPath = [defaults stringForKey:@"path"];
	if([defaultPath length] == 0 || ![[defaultPath substringToIndex:1] isEqualToString:@"/"])
		[path appendString:@"/"];
	if(defaultPath)
		[path appendString:defaultPath];
	if([path length] > 0 && ![[path substringFromIndex:[path length] - 1] isEqualToString:@"/"])
		[path appendString:@"/"];
	[path appendString:encodedFilename];
  
	BOOL changePermissions = [defaults boolForKey:@"change_permissions"];
	NSString *permissionString = nil;
	if (changePermissions) {
		permissionString = [defaults stringForKey:@"permission_string"];
	}
	
	NSString *protocol = [defaults stringForKey:@"protocol"];
	NSString *hostname = [defaults stringForKey:@"host"];
	int port = [[defaults stringForKey:@"port"] intValue];
	NSString *username = [defaults stringForKey:@"username"];
    
    NSString *password = @"";
    NSError *keychainError;
    AHKeychain *keychain = [AHKeychain loginKeychain];
    
    AHKeychainItem *keychainItem = [[AHKeychainItem alloc] init];
    keychainItem.service = @"FileShuttle";
    keychainItem.account = @"";
    if ([keychain getItem:keychainItem error:&keychainError]) {
        password = keychainItem.password;
    }
    	
	MVFileUpload *tmpFileUpload = nil;
	
	if([protocol isEqualToString:@"FTP"]) {
		NSString *destination = [NSString stringWithFormat:
                             @"ftp://%@:%i/%@",hostname,port,path];
    
		tmpFileUpload = [[MVFTPFileUpload alloc] initWithDestination:destination
                                                        username:username
                                                        password:password
                                                          source:source
                                                        delegate:self];
	}
	else if([protocol isEqualToString:@"SFTP"] || [protocol isEqualToString:@"SCP"]) {
		NSString *destination = [NSString stringWithFormat:
                             @"ssh://%@:%i/%@",hostname,port,path];
		
		tmpFileUpload = [[MVSFTPFileUpload alloc] initWithDestination:destination
                                                         username:username
                                                         password:password
                                                           source:source
                                                         delegate:self];
		
		tmpFileUpload.changePermissions = changePermissions;
		tmpFileUpload.permissionString = permissionString;
	}
	
	self.fileUpload = tmpFileUpload;
	[tmpFileUpload release];
  
	self.deleteFile = deleteFile;
	if(self.fileUpload)
		[self.fileUpload start];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark MVFileUploadDelegate methods

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUpload:(MVFileUpload*)fileUpload
  didFailWithError:(NSString*)error
{
	self.tries--;
	[self.fileUpload cancel];
	if(self.tries > 0) {
		[self.fileUpload start];
	}
	else {
		[self deleteFile:fileUpload.source];
		if([self.delegate respondsToSelector:@selector(fileUploader:didFailWithError:)])
			[self.delegate fileUploader:self
                 didFailWithError:error];
		
		self.fileUpload = nil;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploadDidStartUpload:(MVFileUpload *)fileUpload
{
	if([self.delegate respondsToSelector:@selector(fileUploaderDidStart:)])
		[self.delegate fileUploaderDidStart:self];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUploadDidSuccess:(MVFileUpload*)fileUpload
{
	[self deleteFile:fileUpload.source];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *baseurl = [defaults stringForKey:@"baseurl"];
	if(![[baseurl substringFromIndex:[baseurl length] - 1] isEqualToString:@"/"])
		baseurl = [NSString stringWithFormat:@"%@/",baseurl];
  if([baseurl length] < 7 ||
     (![[[baseurl substringToIndex:7] lowercaseString] isEqualToString:@"http://"]
      && ![[[baseurl substringToIndex:8] lowercaseString] isEqualToString:@"https://"]))
    baseurl = [NSString stringWithFormat:@"http://%@",baseurl];
	
	NSString *filename = [fileUpload.destination lastPathComponent];
	
	NSString *url = [NSString stringWithFormat:@"%@%@",baseurl,filename];
	
	if([self.delegate respondsToSelector:@selector(fileUploader:didSuccess:fileName:filePath:)])
		[self.delegate fileUploader:self
                     didSuccess:url
                       fileName:self.filename
                       filePath:self.filepath];
	[self.fileUpload cancel];
	self.fileUpload = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)fileUpload:(MVFileUpload *)fileUpload 
didChangeProgression:(float)progression 
         bytesRead:(long)bytesRead 
        totalBytes:(long)totalBytes
{
	if([self.delegate respondsToSelector:@selector(fileUploader:didChangeProgression:)])
		[self.delegate fileUploader:self didChangeProgression:progression];
}

@end
