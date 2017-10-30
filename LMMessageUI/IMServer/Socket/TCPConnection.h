//
//  TCPConnection.h
//  podcasting
//
//  Created by houxh on 15/6/25.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

typedef NS_OPTIONS(NSUInteger, LMSocketConnectState) {
    LMSocketConnectStateUnConnected = 0,
    LMSocketConnectStateConnecting = 1 << 0,
    LMSocketConnectStateAuthing = 1 << 1,
    LMSocketConnectStateConnected = 1 << 2,
    LMSocketConnectStateUpdatingMessage = 1 << 3,
};


@protocol TCPConnectionObserver <NSObject>
@optional

- (void)onConnectState:(LMSocketConnectState)state;

@end

@interface TCPConnection : NSObject
//public
@property(nonatomic, assign) LMSocketConnectState connectState;
@property(nonatomic) BOOL reachable;

//subclass override
- (BOOL)sendPing;

- (BOOL)handleData:(NSData *)data message:(Message *)message;

- (void)onConnect;

- (void)onClose;

- (void)connecting;

//public method
- (void)write:(NSData *)data;

/**
 * start imserver
 */
- (void)start;

/**
 * heartbeat ack
 */
- (void)pong;

/**
 * imserver close
 */
- (void)close;

/**
 * enterForeground
 */
- (void)enterForeground;

/**
 * enterBackground
 */
- (void)enterBackground;

/**
 * add Connectionstatue Observer
 */
- (void)addConnectionObserver:(id <TCPConnectionObserver>)ob;

/**
 * remove Connection Observer
 */
- (void)removeConnectionObserver:(id <TCPConnectionObserver>)ob;

/**
 * startRechabilityNotifier
 */
- (void)startRechabilityNotifier;

/**
 * publish Connect State
 */
- (void)publishConnectState:(LMSocketConnectState)state;
@end
