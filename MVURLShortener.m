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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger shortenerid = [defaults integerForKey:@"selected_shortener"];
    NSString *apikey = @"";
    NSString *shortenerUrl = @"";
    
    if([defaults objectForKey:@"api_shortener_token"]) {
        apikey = [defaults objectForKey:@"api_shortener_token"];
    }
    
    // is.gd
    if(shortenerid == 0) {
        shortenerUrl = [NSString stringWithFormat:
                        @"http://is.gd/create.php?format=simple&url=%@",url];
    }
    // v.gd
    else if(shortenerid == 1) {
        shortenerUrl = [NSString stringWithFormat:@"http://v.gd/create.php?format=simple&url=%@",url];
    }
    // bit.ly
    else if(shortenerid == 2) {
        shortenerUrl = [NSString stringWithFormat:@"https://api-ssl.bitly.com/v3/shorten?access_token=%@&format=txt&longUrl=%@", apikey, url];
    }
    else if(shortenerid == 3) {
        shortenerUrl = [NSString stringWithFormat:@"https://api-ssl.bitly.com/v3/shorten?access_token=%@&domain=j.mp&format=txt&longUrl=%@", apikey, url];
    }
    
    NSString *response = [NSString stringWithContentsOfURL:[NSURL URLWithString:shortenerUrl]
                                                  encoding:NSUTF8StringEncoding error:nil];
    if(response == nil) return nil;
    if([response isEqual: @"Error: Please enter a valid URL to shorten"] || [response isEqual: @"INVALID_URI"] || [response isEqual: @"MISSING_ARG_ACCESS_TOKEN"]) {
        return nil;
    } else {
        return response;
    }
}

@end