//
//  WSRPCClassStaticMethod.h
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 28/02/14.
//  Copyright (c) 2014 Widespace . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSRPCRequest.h"

#define RPC_PARAM_TYPE_STRING @"STRING"
#define RPC_PARAM_TYPE_NUMBER @"NUMBER"
#define RPC_PARAM_TYPE_ARRAY @"ARRAY"
#define RPC_PARAM_TYPE_DICTIONARY @"OBJECT"
#define RPC_PARAM_TYPE_INSTANCE @"INSTANCE"

@class WSRPCClassMethod;
@class WSRPCClassInstance;
@class WSRPCRemoteObjectController;

/**
 Call to use instead of selector.
 @param instance If this is executed as an instance method the instance will be available here.
 @param theMethod Model object representing the current method to execute as parsed by the RPC Controller.
 @param request The full request that the RPC Controller generated from the interface so you have all params. You have to respond manually by creating a WSRPCResponse from the WSRPCRequest and fire the callback while passing the response as a parameter.
 @see WSRPCClassInstance
 @see WSRPCRequest
 @see WSRPCResponse
 @see callBlock
 */
typedef void (^CallBlock)(WSRPCRemoteObjectController *rpcController, WSRPCClassInstance *instance, WSRPCClassMethod *theMethod, WSRPCRequest *request);

@interface WSRPCClassMethod : NSObject

/**
 Used by the RPC interface to know what message to translate to what method.
 */
@property (nonatomic, strong) NSString *mapName;

/**
 Used to explain what this method does if a description is asked for. Could be called from the RPC interface so give some nice details about how to use the method.
 */
@property (nonatomic, strong) NSString *details;

/**
 Array of strings to represent param types.
 */
@property (nonatomic, strong) NSArray *paramTypes;

/**
 The actual selector to perform.
 */
@property (nonatomic, assign) SEL selector;

/**
 Tell the method object if the invocation returns anything or if it is void.
 @default YES
 */
@property (nonatomic, assign) BOOL isVoidReturn;

/**
 If set this will execute INSTEAD of running the selector with passed params from RPC controller. You may specify exactly how to handle the params using this block and respond to the WSRPCRequest yourself instead of letting the RPC Controller handle that for you. 
 Complete control, YEAH!
 */
@property (nonatomic, copy) CallBlock callBlock;

/**
 Convenience getter for getting the selector as a string.
 */
@property (nonatomic, readonly) NSString *methodName;


+(instancetype)methodWithMapName:(NSString *)mapName selector:(SEL)selector andParamTypes:(NSArray *)paramTypes;
+(instancetype)methodWithMapName:(NSString *)mapName selector:(SEL)selector paramTypes:(NSArray *)paramTypes andVoidReturn:(BOOL)isVoidReturn;
-(instancetype)initWithMapName:(NSString *)mapName selector:(SEL)selector andParamTypes:(NSArray *)paramTypes;
-(instancetype)initWithMapName:(NSString *)mapName selector:(SEL)selector paramTypes:(NSArray *)paramTypes andVoidReturn:(BOOL)isVoidReturn;

@end
