//
//  HTTPResponseHandle.m
//  XiaoX
//
//  Created by pengding on 2017/6/22.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import "HTTPResponseHandler.h"
#import "HTTPServer.h"

@implementation HTTPResponseHandler

static NSMutableArray *registerHandlers = nil;

+ (NSUInteger)priority{
    return 0;
}

+ (void)load{
    [HTTPResponseHandler registerHandler:self];
}

+ (void)registerHandler:(Class)handleClass{
    if (registerHandlers == nil) {
        registerHandlers = [[NSMutableArray alloc]init];
    }
    NSUInteger i;
    NSUInteger count = [registerHandlers count];
    for (i = 0; i < count; i++) {
        if ([handleClass priority] >= [[registerHandlers objectAtIndex:i] priority]) {
            break;
        }
    }
    [registerHandlers insertObject:handleClass atIndex:i];
}

+ (BOOL)canHandleRequest:(CFHTTPMessageRef)aRequest
                  method:(NSString *)requestMethod
                     url:(NSURL *)requestURL
            headerFields:(NSDictionary *)requestHeaderFields{
    return YES;
}

+ (Class)handlerClassForRequest:(CFHTTPMessageRef)aRequest
                         method:(NSString *)requestMethod
                            url:(NSURL *)requestURL
                   headerFields:(NSDictionary *)requestHeaderFields{
    for (Class handlerClass in registerHandlers) {
        if ([handlerClass canHandleRequest:aRequest
                                    method:requestMethod
                                       url:requestURL
                              headerFields:requestHeaderFields]) {
            return handlerClass;
        }
    }
    return nil;
}

+ (HTTPResponseHandler *)handlerForRequest:(CFHTTPMessageRef)aRequest
                               fileHandle:(NSFileHandle *)requestFileHandle
                                   server:(HTTPServer *)aServer{
    NSDictionary *requestHeaderFields =
    (__bridge  NSDictionary *)CFHTTPMessageCopyAllHeaderFields(aRequest);
    NSURL *requestURL =
    (__bridge NSURL *)CFHTTPMessageCopyRequestURL(aRequest);
    NSString *method =
    (__bridge NSString *)CFHTTPMessageCopyRequestMethod(aRequest)
     ;

    Class classForRequest =
    [self handlerClassForRequest:aRequest
                          method:method
                             url:requestURL
                    headerFields:requestHeaderFields];

    HTTPResponseHandler *handler = [[classForRequest alloc]
                                    initWithRequest:aRequest
                                    method:method
                                    url:requestURL
                                    headerFields:requestHeaderFields
                                    fileHandle:requestFileHandle
                                    server:aServer];

    return handler;
}

- (instancetype)initWithRequest:(CFHTTPMessageRef)aRequest
                         method:(NSString *)method
                            url:(NSURL *)requsetURL
                   headerFields:(NSDictionary *)requestHeaderFields
                     fileHandle:(NSFileHandle *)requsetFileHandle
                         server:(HTTPServer *)aServer{
    self = [super init];
    if (self) {
        request = aRequest;
        requestMethod = method;
        url = requsetURL;
        headerFields = requestHeaderFields;
        fileHandle = requsetFileHandle;
        server = aServer;
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(receiveIncomingDataNotification:) name:NSFileHandleDataAvailableNotification
                                                  object:fileHandle];
    }
    return self;
}


- (void)startResponse{
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 501, NULL, kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (CFStringRef)@"text/html");
    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
    NSString *dataString = @"<html><head><title>501 - Not Implemented</title></head>"
                           @"<body><h1>501 - Not Implemented</h1>"
                           @"<p>0-0......</p></body></html>";

    CFHTTPMessageSetBody(response, (__bridge  CFDataRef)[dataString dataUsingEncoding:NSUTF8StringEncoding]);
    CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
    @try{
        [fileHandle writeData:(__bridge NSData *)headerData];
    }
    @catch(NSException *exception){

    }
    @finally{
        CFRelease(headerData);
        CFRelease(response);
        [server closeHandler:self];
    }

}

- (void)endResponse{
    if (fileHandle) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleDataAvailableNotification
                                                      object:fileHandle];
        [fileHandle closeFile];
        fileHandle = nil;
    }
    server = nil;
}

- (void)receiveIncomingDataNotification:(NSNotification *)notification{
    NSLog(@"-----------------\n%@",notification);
    NSFileHandle *incomingFileHandle = [notification object];
    NSData *data = [incomingFileHandle availableData];
    if ([data length] == 0) {
        [server closeHandler:self];
    }

    [incomingFileHandle waitForDataInBackgroundAndNotify];
}

- (void)dealloc{
    if (server) {
        [self endResponse];
    }
    if (request) {
        request = nil;
    }
    if (requestMethod) {
        requestMethod = nil;
    }
    if (url) {
        url = nil;
    }
    if (headerFields) {
        headerFields = nil;
    }
}


@end
