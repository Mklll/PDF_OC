//
//  HTTPServer.h
//  XiaoX
//
//  Created by pengding on 2017/6/22.
//  Copyright © 2017年 pengding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
    HTTPServerState_IDLE = 0,
    HTTPServerState_STARTING,
    HTTPServerState_RUNNING,
    HTTPServerState_STOPPING
} HTTPServerState;

extern NSString * const HTTPServerNotificationStateChanged;

@class HTTPResponseHandler;


@interface HTTPServer : NSObject
{
    NSFileHandle *listeningHandle;
    CFSocketRef socket;
    HTTPServerState _state;
    CFMutableDictionaryRef incomingRequests;
    NSMutableSet *responseHandlers;
}
@property (nonatomic, readwrite, retain) NSError *lastError;
@property (readwrite, assign,nonatomic) HTTPServerState state;
+ (HTTPServer *)sharedHTTPServer;

- (void)start;
- (void)stop;

- (void)closeHandler:(HTTPResponseHandler *)aHandler;

@end
