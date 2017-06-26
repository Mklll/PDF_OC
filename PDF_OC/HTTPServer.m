//
//  HTTPServer.m
//  XiaoX
//
//  Created by pengding on 2017/6/22.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import "HTTPServer.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CFSocket.h>
#import <NetworkExtension/NetworkExtension.h>
#import "HTTPResponseHandler.h"


#define HTTP_SERVER_PORT  8080
NSString * const HTTPServerNotificationStateChanged = @"ServerNotificationStateChanged";



@implementation HTTPServer
@dynamic state;

+ (instancetype)sharedHTTPServer{
    static HTTPServer *newServer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        newServer = [[HTTPServer alloc]init];
    });
    return newServer;

}
- (instancetype)init{
    if (self = [super init]) {
        self.state = HTTPServerState_IDLE;
        responseHandlers = [[NSMutableSet alloc]init];
        incomingRequests = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                     0,
                                                     &kCFTypeDictionaryKeyCallBacks,
                                                     &kCFTypeDictionaryValueCallBacks);

    }
    return self;
}


- (void)stopReceivingForFileHandle:(NSFileHandle *)incomingFileHandle
                             close:(BOOL)closeFileHandle{
    if (closeFileHandle) {
        [incomingFileHandle closeFile];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleDataAvailableNotification
                                                  object:incomingFileHandle];
    CFDictionaryRemoveValue(incomingRequests,(void *)incomingFileHandle);
}

- (void)receiveIncomingConnectionNotification:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *incomingFileHandle =
    [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];

    if(incomingFileHandle)
    {
        CFDictionaryAddValue(
                             incomingRequests,
                             (__bridge void *)incomingFileHandle,
                             (const void *)CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE));

        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(receiveIncomingDataNotification:)
         name:NSFileHandleDataAvailableNotification
         object:incomingFileHandle];

        [incomingFileHandle waitForDataInBackgroundAndNotify];
    }

    [listeningHandle acceptConnectionInBackgroundAndNotify];
}

- (void)start{
    socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, NULL, NULL);
    if (!socket ) {
        NSLog(@"--------------------\n创建socket失败");
        return;
    }
    int reuse = true;
    int fileDescirptor = CFSocketGetNative(socket);
    if ( setsockopt(fileDescirptor, SOL_SOCKET, SO_REUSEADDR, (void *)&reuse, sizeof(int)) != 0 ) {
        NSLog(@"--------------------\n set失败");

        return;
    }
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(HTTP_SERVER_PORT);
    CFDataRef addressData = CFDataCreate(NULL, (const UInt8*)&address, sizeof(address));

    if (CFSocketSetAddress(socket, addressData) != kCFSocketSuccess) {
        NSLog(@"---------------------\n 绑定地址错误");
        return;
    }

    listeningHandle = [[NSFileHandle alloc]initWithFileDescriptor:fileDescirptor closeOnDealloc:YES];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(receiveIncomingConnectionNotification:)
                                                name:NSFileHandleConnectionAcceptedNotification
                                              object:nil];
    [listeningHandle acceptConnectionInBackgroundAndNotify];
    self.state = HTTPServerState_RUNNING;
}

- (void)stop{
    self.state = HTTPServerState_STOPPING;
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:NSFileHandleConnectionAcceptedNotification
                                                 object:nil];
    [responseHandlers removeAllObjects];
    [listeningHandle closeFile];
    listeningHandle = nil;
    for (NSFileHandle *incomingFileHandle in (__bridge NSDictionary*)incomingRequests ) {
        [self stopReceivingForFileHandle:incomingFileHandle close:YES];

    }
    if (socket) {
        CFSocketInvalidate(socket);
        CFRelease(socket);
        socket = nil;
    }
    self.state = HTTPServerState_IDLE;



}


- (void)receiveIncomingDataNotification:(NSNotification *)notification
{
    NSFileHandle *incomingFileHandle = [notification object];
    NSData *data = [incomingFileHandle availableData];

    if ([data length] == 0)
    {
        [self stopReceivingForFileHandle:incomingFileHandle close:NO];
        return;
    }

    CFHTTPMessageRef incomingRequest =
    (CFHTTPMessageRef)CFDictionaryGetValue(incomingRequests,(const void *) incomingFileHandle);
    if (!incomingRequest)
    {
        [self stopReceivingForFileHandle:incomingFileHandle close:YES];
        return;
    }

    if (!CFHTTPMessageAppendBytes(
                                  incomingRequest,
                                  [data bytes],
                                  [data length]))
    {
        [self stopReceivingForFileHandle:incomingFileHandle close:YES];
        return;
    }

    if(CFHTTPMessageIsHeaderComplete(incomingRequest))
    {
        HTTPResponseHandler *handler = [HTTPResponseHandler
                                        handlerForRequest:incomingRequest
                                        fileHandle:incomingFileHandle
                                        server:self];

        [responseHandlers addObject:handler];
        [self stopReceivingForFileHandle:incomingFileHandle close:NO];
        [handler startResponse];
        return;
    }

    [incomingFileHandle waitForDataInBackgroundAndNotify];
}


- (void)closeHandler:(HTTPResponseHandler *)aHandler{
    [aHandler endResponse];
    [responseHandlers removeObject:aHandler];
}



- (void)errorWithName:(NSString *)errorName
{
    self.lastError = [NSError
                      errorWithDomain:@"HTTPServerError"
                      code:0
                      userInfo:
                      [NSDictionary dictionaryWithObject:
                       NSLocalizedStringFromTable(
                                                  errorName,
                                                  @"",
                                                  @"HTTPServerErrors")
                                                  forKey:NSLocalizedDescriptionKey]];
}

- (void)setState:(HTTPServerState)state{
    if (_state == state) {
        return;
    }
    _state = state;
    [[NSNotificationCenter defaultCenter]postNotificationName:HTTPServerNotificationStateChanged object:self];
}

- (void)setLastError:(NSError *)lastError{


    _lastError = lastError;

    if (lastError == nil)
    {
        return;
    }

    [self stop];
    self.state = HTTPServerState_IDLE;
    NSLog(@"HTTPServer error: %@", self.lastError);
}



@end
