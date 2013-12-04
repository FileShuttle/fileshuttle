//
//  MVURLShortener.m
//  FileShuttle
//
//  Created by Michael Villar on 12/11/11.
//

#import "MVURLShortener.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MVURLShortener

///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)shortenURL:(NSString*)url {
	NSString *shttleUrl = [NSString stringWithFormat:
                         @"http://is.gd/create.php?format=simple&url=%@",url];
	NSString *doc = [NSString stringWithContentsOfURL:[NSURL URLWithString:shttleUrl]
                                           encoding:NSUTF8StringEncoding error:nil];
	if(doc == nil) return nil;
	
    if([doc isEqual: @"Error: Please enter a valid URL to shorten"]) {
        return nil;
    } else {
        return doc;
    }
}

@end
