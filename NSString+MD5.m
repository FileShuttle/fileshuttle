//
//  NSString+MD5.m
//  FileShuttle
//
//  Created by Michaël on 26/04/11.
//

#import "NSString+MD5.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NSString (MD5)

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)md5 {
    NSData *md5data = [self dataUsingEncoding:NSUTF8StringEncoding];

    const char *md5datastring = [md5data bytes];
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(md5datastring, strlen(md5datastring), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *digestStr = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [digestStr appendFormat:@"%02x",md5Buffer[i]];

	return digestStr;
}

@end
