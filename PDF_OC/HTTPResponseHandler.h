//
//  HTTPResponseHandle.h
//  XiaoX
//
//  Created by pengding on 2017/6/22.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>

@class HTTPServer;

@interface HTTPResponseHandler : NSObject
{
    CFHTTPMessageRef request;
    NSString *requestMethod;
    NSDictionary *headerFields;
    NSFileHandle *fileHandle;
    HTTPServer *server;
    NSURL *url;
}

+ (NSUInteger)priority;
+ (void)registerHandler:(Class)handleClass;

+ (HTTPResponseHandler *)handlerForRequest:(CFHTTPMessageRef)aRequest
                               fileHandle:(NSFileHandle *)requestFileHandle
                                   server:(HTTPServer *)aServer;

- (instancetype)initWithRequest:(CFHTTPMessageRef)aRequest
                         method:(NSString *)method
                            url:(NSURL *)requsetURL
                   headerFields:(NSDictionary *)requestHeaderFields
                     fileHandle:(NSFileHandle *)requsetFileHandle
                         server:(HTTPServer *)aServer;

- (void)startResponse;
- (void)endResponse;

@end
