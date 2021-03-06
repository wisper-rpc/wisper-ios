//
//  WSPRRemoteObject.m
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 07/01/16.
//  Copyright © 2016 Widespace . All rights reserved.
//

#import "WSPRRemoteObject.h"
#import "WSPRRemoteObjectRouter.h"
#import "WSPRGatewayRouter.h"

@interface WSPRRemoteObject ()

@property (nonatomic, strong) NSString *instanceIdentifier;
@property (nonatomic, strong) NSString *mapName;
@property (nonatomic, strong) WSPRGatewayRouter *gatewayRouter;

@property (nonatomic, strong) NSMutableArray *_wisperInstanceNotificationQueue;

@end

@implementation WSPRRemoteObject


#pragma mark - Lifecycle

//Disallow just init so that we can be sure that mapName and gateWay are present? Or we can have a check in the method calls.
-(instancetype)initWithMapName:(NSString *)mapName andGatewayRouter:(WSPRGatewayRouter *)gatewayRouter
{
    self = [super init];
    if (self)
    {
        self.mapName = mapName;
        self.gatewayRouter = gatewayRouter;
        self._wisperInstanceNotificationQueue = [NSMutableArray array];
        [self setAutomaticRemoteForwardingEnabled:YES];
        [self _initRemoteObjectWithParams:nil];
        [self _registerEventRouter];
    }
    return self;
}

-(void)dealloc
{
    [self _unregisterEventRouter];
    [self _destroyRemoteObject];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSignature = [[self class] instanceMethodSignatureForSelector:aSelector];
    
    if (!methodSignature)
    {
        NSString *selectorString = NSStringFromSelector(aSelector);
        NSInteger numberOfArgs = [[selectorString componentsSeparatedByString:@":"] count] - 1;
        
        NSMutableString *signatureTypesString = [NSMutableString stringWithString:@"v@:"];
        
        for (NSInteger i = 0; i < numberOfArgs; i++)
        {
            [signatureTypesString appendString:@"@"];
        }
        
        methodSignature = [NSMethodSignature signatureWithObjCTypes:[signatureTypesString UTF8String]];
    }
    
    return methodSignature;
}

-(void)forwardInvocation:(NSInvocation *)anInvocation
{
    BOOL isVoidReturn = (strncmp([[anInvocation methodSignature] methodReturnType], "v", 1) == 0);
    if (self.isAutomaticRemoteForwardingEnabled && isVoidReturn)
    {
        //Turn into RPC message and call
        [self _wisperCallInstanceMethod:[self _wisperMethodNameFromSelector:[anInvocation selector]] withParams:[self _wisperMethodParamsFromInvocation:anInvocation]];
    }
    else
    {
        [super forwardInvocation:anInvocation];
    }
}


#pragma mark - Setters and Getters

-(void)setInstanceIdentifier:(NSString *)instanceIdentifier
{
    if (_instanceIdentifier != instanceIdentifier)
    {
        _instanceIdentifier = instanceIdentifier;
        [self _wisperSendQueuedInstanceNotifications];
    }
}


#pragma mark - Actions

-(void)_wisperCallInstanceMethod:(NSString *)method withParams:(NSArray *)params andCompletion:(void (^)(NSObject *, WSPRError *))completion
{
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.method = [NSString stringWithFormat:@"%@:%@", self.mapName, method];
    request.params = params;
    request.responseBlock = ^(WSPRResponse *response) {
        //Handle completion
        completion(response.result, response.error);
    };
    
    [self _wisperSendInstanceNotification:request];
}

-(void)_wisperCallStaticMethod:(NSString *)method withParams:(NSArray *)params andCompletion:(void (^)(NSObject *, WSPRError *))completion
{
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.method = [NSString stringWithFormat:@"%@.%@", self.mapName, method];
    request.params = params;
    request.responseBlock = ^(WSPRResponse *response) {
        //Handle completion
        completion(response.result, response.error);
    };
    
    [self.gatewayRouter.gateway sendMessage:request];
}

-(void)_wisperCallInstanceMethod:(NSString *)method withParams:(NSArray *)params
{
    WSPRNotification *notification = [[WSPRNotification alloc] init];
    notification.method = [NSString stringWithFormat:@"%@:%@", self.mapName, method];
    notification.params = params;
    
    [self _wisperSendInstanceNotification:notification];
}

-(void)_wisperCallStaticMethod:(NSString *)method withParams:(NSArray *)params
{
    WSPRNotification *notification = [[WSPRNotification alloc] init];
    notification.method = [NSString stringWithFormat:@"%@.%@", self.mapName, method];
    notification.params = params;
    
    [self.gatewayRouter.gateway sendMessage:notification];
}

-(void)_wisperSendInstanceEventWithName:(NSString *)name andValue:(NSObject *)value
{
    WSPRNotification *notification = [[WSPRNotification alloc] init];
    notification.method = [NSString stringWithFormat:@"%@:!", self.mapName];
    notification.params = @[name, value];

    [self _wisperSendInstanceNotification:notification];
}

-(void)_wisperSendStaticEventWithName:(NSString *)name andValue:(NSObject *)value
{
    WSPRNotification *notification = [[WSPRNotification alloc] init];
    notification.method = [NSString stringWithFormat:@"%@!", self.mapName];
    notification.params = @[name, value];
    
    [self.gatewayRouter.gateway sendMessage:notification];
}

+(void)rpcHandleStaticEvent:(WSPREvent *)event
{
    //Override in subclass
}

-(void)rpcHandleInstanceEvent:(WSPREvent *)event
{
    //Override in subclass
}


#pragma mark - Private Actions

-(void)_initRemoteObjectWithParams:(NSArray *)params
{
    __weak WSPRRemoteObject *weakSelf = self;
    __weak WSPRGateway *weakGateway = self.gatewayRouter.gateway;
    NSString *mapName = self.mapName; //Will be retained for the lifetime of the response block
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.method = [NSString stringWithFormat:@"%@~", mapName];
    request.params = params ? : @[];
    request.responseBlock = ^(WSPRResponse *response) {
        if ([response isKindOfClass:[WSPRResponse class]] && response.result)
        {
            if (weakSelf)
            {
                weakSelf.instanceIdentifier = ((NSDictionary *)response.result)[@"id"];
            }
            else
            {
                //TODO: Cover this case with unit test
                WSPRNotification *destroyNotification = [[WSPRNotification alloc] init];
                destroyNotification.method = [NSString stringWithFormat:@"%@:~", mapName];
                destroyNotification.params = @[((NSDictionary *)response.result)[@"id"]];
                [weakGateway sendMessage:destroyNotification];
            }
        }
    };
    [self.gatewayRouter.gateway sendMessage:request];
}

-(void)_destroyRemoteObject
{
    if (!self.instanceIdentifier)
        return;
    
    WSPRNotification *destroyNotification = [[WSPRNotification alloc] init];
    destroyNotification.method = [NSString stringWithFormat:@"%@:~", self.mapName];
    destroyNotification.params = @[self.instanceIdentifier];
    [self.gatewayRouter.gateway sendMessage:destroyNotification];
}

-(void)_registerEventRouter
{
    //See if we have an event router already
    WSPRRouter *eventRouter = [self.gatewayRouter routerAtPath:self.mapName];
    if (!eventRouter)
    {
        //No existing router so we create one
        eventRouter = [[WSPRRemoteObjectRouter alloc] initWithRemoteObjectClass:[self class]];
        [self.gatewayRouter exposeRoute:eventRouter onPath:self.mapName];
    }
    
    //Register for events
    if ([eventRouter isKindOfClass:[WSPRRemoteObjectRouter class]])
    {
        [(WSPRRemoteObjectRouter *)eventRouter registerRemoteObjectInstance:self];
    }
}

-(void)_unregisterEventRouter
{
    //See if we have an event router already
    WSPRRouter *eventRouter = [self.gatewayRouter routerAtPath:self.mapName];

    //Unregister for events
    if ([eventRouter isKindOfClass:[WSPRRemoteObjectRouter class]])
    {
        [(WSPRRemoteObjectRouter *)eventRouter unregisterRemoteObjectInstance:self];
    }
}


#pragma mark - Helper Methods

-(void)_wisperSendInstanceNotification:(WSPRNotification *)notification
{
    if (!self.instanceIdentifier)
    {
        //Put on queue
        [self._wisperInstanceNotificationQueue addObject:notification];
        return;
    }
    
    WSPRNotification *instanceNotification = [self _insertInstanceIdentifierInParamsForNotification:notification];
    [self.gatewayRouter.gateway sendMessage:instanceNotification];
}

-(void)_wisperSendQueuedInstanceNotifications
{
    NSArray *notifications = [NSArray arrayWithArray:self._wisperInstanceNotificationQueue];
    [self._wisperInstanceNotificationQueue removeAllObjects];
    
    for (WSPRNotification *notification in notifications)
    {
        [self _wisperSendInstanceNotification:notification];
    }
}

-(NSString *)_wisperMethodNameFromSelector:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSRange firstArgumentRange = [selectorString rangeOfString:@":"];
    
    if (firstArgumentRange.location == NSNotFound)
    {
        return selectorString;
    }
    
    return [selectorString substringToIndex:firstArgumentRange.location];
}

-(NSArray *)_wisperMethodParamsFromInvocation:(NSInvocation *)invocation
{
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSMutableArray *params = [NSMutableArray array];
    
    for (NSUInteger i = 2; i < methodSignature.numberOfArguments; i++)
    {
        NSObject *argument = nil;
        [invocation getArgument:&argument atIndex:i];
        [params addObject:argument ? : [NSNull null]];
    }
    
    return [NSArray arrayWithArray:params];
}

-(WSPRNotification *)_insertInstanceIdentifierInParamsForNotification:(WSPRNotification *)notification
{
    NSMutableArray *instanceParams = [NSMutableArray arrayWithArray:notification.params];
    [instanceParams insertObject:self.instanceIdentifier atIndex:0];
    notification.params = [NSArray arrayWithArray:instanceParams];
    
    return notification;
}


@end
