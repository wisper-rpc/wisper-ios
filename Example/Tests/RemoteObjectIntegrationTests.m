//
//  RemoteObjectIntegrationTests.m
//  Wisper
//
//  Created by Patrik Nyblad on 17/02/16.
//  Copyright © 2016 Patrik Nyblad. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "WSPRTestObject.h"
#import "WSPRGatewayRouter.h"
#import "WSPRClassRouter.h"
#import "WSPRInstanceRegistry.h"

//TODO: Add exception tests to everything!
//TODO: Add tests for flushing instances on route
//TODO: Add tests for events/notification back from remote object
//TODO: Add tests for wrong method name
//TODO: Add tests for bad params
//TODO: Add tests for serializing instance
//TODO: Add tests for deserializing instance
//TODO: Add functionality for getting the same access as with blocks in methods by specifying special parameter types
//TODO: Remove the need for `isVoidReturn`
//TODO: Add router for blocks/functions
//TODO: Create remote object for exposing routes that are available on one bridge to another
//TODO: Implement proxying


@interface WSPRTestObject ()

-(instancetype)initWithTestPropertyValue:(NSString *)testString;

@end

@interface RemoteObjectIntegrationTests : XCTestCase

@property (nonatomic, strong) WSPRGatewayRouter *gatewayRouter;

@end

@implementation RemoteObjectIntegrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.gatewayRouter = [[WSPRGatewayRouter alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - Registering

- (void)testRegisterTestObject
{
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRouter *wispRouter = _gatewayRouter.routes[@"wisp"];
    WSPRRouter *testRouter = wispRouter.routes[@"test"];
    WSPRClassRouter *testObjectRouter = testRouter.routes[@"TestObject"];
    
    XCTAssertEqual(testObjectRouter.classModel.classRef, [WSPRTestObject class], @"Test Object not registered properly!");
}


#pragma mark - Instance creation

- (void)testNormalCreateInstance
{
    //Disable custom init method
    WSPRClass *testObjectClassModel = [WSPRTestObject rpcRegisterClass];
    testObjectClassModel.instanceMethods = @{};
    id classMock = OCMClassMock([WSPRTestObject class]);
    OCMStub([classMock rpcRegisterClass]).andReturn(testObjectClassModel);
    
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.requestIdentifier = @"create0";
    request.method = @"wisp.test.TestObject~";
    request.responseBlock = ^(WSPRResponse *response){
        NSString *instanceId = [(NSDictionary *)response.result objectForKey:@"id"];
        
        if ([[[WSPRInstanceRegistry instanceWithId:instanceId underRootRoute:_gatewayRouter] instance] isKindOfClass:[WSPRTestObject class]])
            [expectation fulfill];
    };
    
    [_gatewayRouter.gateway handleMessage:request];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testCustomCreateInstance
{
    //Disable block init method
    WSPRClass *testObjectClassModel = [WSPRTestObject rpcRegisterClass];
    [(WSPRClassMethod *)testObjectClassModel.instanceMethods[@"~"] setCallBlock:nil];
    id classMock = OCMClassMock([WSPRTestObject class]);
    OCMStub([classMock rpcRegisterClass]).andReturn(testObjectClassModel);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.requestIdentifier = @"create0";
    request.method = @"wisp.test.TestObject~";
    request.params = @[@"some init value"];
    request.responseBlock = ^(WSPRResponse *response){
        NSString *instanceId = [(NSDictionary *)response.result objectForKey:@"id"];
        NSString *testPropertyValue = [(NSDictionary *)response.result objectForKey:@"props"][@"testProperty"];
        if ([[[WSPRInstanceRegistry instanceWithId:instanceId underRootRoute:_gatewayRouter] instance] isKindOfClass:[WSPRTestObject class]] && [testPropertyValue isEqualToString:@"some init value"])
            [expectation fulfill];
    };
    
    [_gatewayRouter.gateway handleMessage:request];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testBlockCreateInstance
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.requestIdentifier = @"create0";
    request.method = @"wisp.test.TestObject~";
    request.params = @[@"ASD"];
    request.responseBlock = ^(WSPRResponse *response){
        NSString *instanceId = [(NSDictionary *)response.result objectForKey:@"id"];
        
        if ([[[WSPRInstanceRegistry instanceWithId:instanceId underRootRoute:_gatewayRouter] instance] isKindOfClass:[WSPRTestObject class]])
            [expectation fulfill];
    };
    
    [_gatewayRouter.gateway handleMessage:request];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}


#pragma mark - Instance destruction

- (void)testDestroyInstance
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        //Weak object should be nilled when destroyed
        __weak id testObjectMock = OCMPartialMock(instance.instance);
        __weak WSPRClassInstance *weakInstance = instance;
        
        
        //Copy instance ID so we have it after instance is removed
        NSString *instanceId = instance.instanceIdentifier;
        
        OCMExpect([testObjectMock rpcDestructor]).andForwardToRealObject();
        
        //Destroy the instance
        WSPRRequest *request = [[WSPRRequest alloc] init];
        request.requestIdentifier = @"destroy0";
        request.method = @"wisp.test.TestObject:~";
        request.params = @[instanceId];
        request.responseBlock = ^(WSPRResponse *response){
            OCMVerifyAll(testObjectMock);
            [testObjectMock stopMocking]; //Really important to stop mocking here since removing KVO will not work otherwise

            if (![WSPRInstanceRegistry instanceWithId:instanceId underRootRoute:_gatewayRouter])
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!weakInstance) {
                        [expectation fulfill];
                    }
                });
        };
        
        [_gatewayRouter.gateway handleMessage:request];
        
    }];
    
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}


#pragma mark - Method invocation

- (void)testNotifyStaticMethod
{
    id testObjectClassMock = OCMClassMock([WSPRTestObject class]);
    
    OCMExpect(ClassMethod([testObjectClassMock appendString:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [(NSString *)obj isEqualToString:@"Hello "];
    }] withString:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [(NSString *)obj isEqualToString:@"world!"];
    }]]));
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRNotification *notification = [[WSPRNotification alloc] init];
    notification.method = @"wisp.test.TestObject.append";
    notification.params = @[@"Hello ", @"world!"];
    
    [_gatewayRouter.gateway handleMessage:notification];
    
    OCMVerifyAll(testObjectClassMock);
}

- (void)testRequestStaticMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"correct response"];
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.requestIdentifier = @"static0";
    request.method = @"wisp.test.TestObject.append";
    request.params = @[@"Hello ", @"world!"];
    request.responseBlock = ^(WSPRResponse *response){
        if ([(NSString *)response.result isEqualToString:@"Hello world!"])
            [expectation fulfill];
    };
    
    [_gatewayRouter.gateway handleMessage:request];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testNotifyInstanceMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];

    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        id testObjectMock = OCMPartialMock(instance.instance);
        
        OCMExpect([testObjectMock appendString:[OCMArg checkWithBlock:^BOOL(id obj) {
            return [(NSString *)obj isEqualToString:@"Hello "];
        }] withString:[OCMArg checkWithBlock:^BOOL(id obj) {
            return [(NSString *)obj isEqualToString:@"world!"];
        }]]);

        WSPRNotification *notification = [[WSPRNotification alloc] init];
        notification.method = @"wisp.test.TestObject:append";
        notification.params = @[instance.instanceIdentifier, @"Hello ", @"world!"];
        
        [_gatewayRouter.gateway handleMessage:notification];
        
        OCMVerifyAll(testObjectMock);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testRequestInstanceMethod
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        WSPRRequest *request = [[WSPRRequest alloc] init];
        request.requestIdentifier = @"instance0";
        request.method = @"wisp.test.TestObject:append";
        request.params = @[instance.instanceIdentifier, @"Hello ", @"world!"];
        request.responseBlock = ^(WSPRResponse *response){
            if ([(NSString *)response.result isEqualToString:@"Hello world!"])
                [expectation fulfill];
        };
        [_gatewayRouter.gateway handleMessage:request];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}


#pragma mark - Event handling

- (void)testStaticEvent
{
    id testObjectClassMock = OCMClassMock([WSPRTestObject class]);
    
    WSPREvent *event = [[WSPREvent alloc] init];
    event.name = @"progress";
    event.mapName = @"wisp.test.TestObject";
    event.data = @(1.0);
    
    OCMExpect(ClassMethod([testObjectClassMock rpcHandleStaticEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        WSPREvent *event = (WSPREvent *)obj;
        if (event.instanceIdentifier && event.instanceIdentifier.length > 0)
            return NO;
        
        if (![event.name isEqualToString:@"progress"])
            return NO;
        
        if (![event.mapName isEqualToString:@"wisp.test.TestObject"])
            return NO;
        
        if ([(NSNumber *)event.data floatValue] != 1.0f)
            return NO;
        
        return YES;
    }]]));
    
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    [_gatewayRouter.gateway handleMessage:[event createNotification]];
    
    OCMVerifyAll(testObjectClassMock);
}

- (void)testInstanceEvent
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        id testObjectMock = OCMPartialMock(instance.instance);
        
        WSPREvent *event = [[WSPREvent alloc] init];
        event.name = @"progress";
        event.mapName = @"wisp.test.TestObject";
        event.instanceIdentifier = instance.instanceIdentifier;
        event.data = @(1.0);
        
        OCMExpect([testObjectMock rpcHandleInstanceEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
            WSPREvent *event = (WSPREvent *)obj;
            if (![event.instanceIdentifier isEqualToString:instance.instanceIdentifier])
                return NO;
            
            if (![event.name isEqualToString:@"progress"])
                return NO;
            
            if (![event.mapName isEqualToString:@"wisp.test.TestObject"])
                return NO;
            
            if ([(NSNumber *)event.data floatValue] != 1.0f)
                return NO;
            
            return YES;
        }]]);
        
        [_gatewayRouter.gateway handleMessage:[event createNotification]];
        
        OCMVerifyAll(testObjectMock);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testInstancePropertyEvent
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        WSPREvent *event = [[WSPREvent alloc] init];
        event.name = @"testProperty";
        event.mapName = @"wisp.test.TestObject";
        event.instanceIdentifier = instance.instanceIdentifier;
        event.data = @"instance property test value";
        
        [_gatewayRouter.gateway handleMessage:[event createNotification]];
        
        if ([[(WSPRTestObject *)instance.instance testProperty] isEqualToString:@"instance property test value"])
            [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testInstancePropertyUpdatedEvent
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"instance created"];
    
    [self testObjectInstanceWithCompletion:^(WSPRClassInstance *instance) {
        
        id gatewayMock = OCMPartialMock(_gatewayRouter.gateway);
        
        OCMExpect([gatewayMock sendMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
            WSPRNotification *notification = (WSPRNotification *)obj;
            WSPREvent *event = [[WSPREvent alloc] initWithNotification:notification];
            
            if (![event.name isEqualToString:@"testProperty"])
                return NO;
            
            if (![event.data isEqualToString:@"testChange"])
                return NO;
            
            if (![event.instanceIdentifier isEqualToString:instance.instanceIdentifier])
                return NO;
            
            if (![event.mapName isEqualToString:@"wisp.test.TestObject"])
                return NO;
            
            return YES;
        }]]);
        
        [(WSPRTestObject *)instance.instance setTestProperty:@"testChange"];
        
        OCMVerifyAll(gatewayMock);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}


#pragma mark - Helpers

- (void)testObjectInstanceWithCompletion:(void (^)(WSPRClassInstance *instance))completion
{
    [_gatewayRouter exposeRoute:[WSPRClassRouter routerWithClass:[WSPRTestObject class]] onPath:@"wisp.test.TestObject"];
    
    WSPRRequest *request = [[WSPRRequest alloc] init];
    request.requestIdentifier = @"create0";
    request.method = @"wisp.test.TestObject~";
    request.params = @[@"a"];
    request.responseBlock = ^(WSPRResponse *response){
        NSString *instanceId = [(NSDictionary *)response.result objectForKey:@"id"];
        WSPRClassInstance *instance = [WSPRInstanceRegistry instanceWithId:instanceId underRootRoute:_gatewayRouter];
        completion(instance);
    };
    
    [_gatewayRouter.gateway handleMessage:request];
}

@end
