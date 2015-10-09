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
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(md5data, strlen(md5data), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *digestStr = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [digestStr appendFormat:@"%02x",md5Buffer[i]];
	//unsigned char *digest = MD5([md5data bytes], [md5data length], NULL);
//    
//	NSString *digestStr = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//						   digest[0], digest[1], 
//						   digest[2], digest[3],
//						   digest[4], digest[5],
//						   digest[6], digest[7],
//						   digest[8], digest[9],
//						   digest[10], digest[11],
//						   digest[12], digest[13],
//						   digest[14], digest[15]];
	return digestStr;
}

@end
