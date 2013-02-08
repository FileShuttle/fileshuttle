//
//  CURLProtocol.h
//  CURLHandle
//
//  Created by Mike Abdullah on 19/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "CURLHandle.h"


@interface NSURLRequest (CURLProtocol)
- (BOOL)shouldUseCurlHandle;
@end


@interface NSMutableURLRequest (CURLProtocol)
// Setting to YES automatically registers CURLProtocol with NSURLProtocol. You can do so earlier, manually if required
- (void)setShouldUseCurlHandle:(BOOL)useCurl;
@end


@interface CURLProtocol : NSURLProtocol <CURLHandleDelegate>

@end
