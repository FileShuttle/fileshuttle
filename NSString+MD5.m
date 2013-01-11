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
	unsigned char *digest = MD5([md5data bytes], [md5data length], NULL);
	NSString *digestStr = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
						   digest[0], digest[1], 
						   digest[2], digest[3],
						   digest[4], digest[5],
						   digest[6], digest[7],
						   digest[8], digest[9],
						   digest[10], digest[11],
						   digest[12], digest[13],
						   digest[14], digest[15]];
	return digestStr;
}

@end
