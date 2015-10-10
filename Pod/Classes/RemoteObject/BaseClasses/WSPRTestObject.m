//
//  WSPRTestObject.m
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 16/05/14.
//  Copyright (c) 2014 Widespace . All rights reserved.
//

#import "WSPRTestObject.h"

@implementation WSPRTestObject

+(WSPRClass *)rpcRegisterClass
{
    WSPRClass *classModel = [[WSPRClass alloc] init];
    classModel.classRef = [self class];
    classModel.mapName = @"wisp.test.TestObject";
    
    WSPRClassMethod *appendMethod = [[WSPRClassMethod alloc] init];
    appendMethod.mapName = @"append";
    appendMethod.selector = @selector(appendString:withString:);
    appendMethod.isVoidReturn = NO;
    appendMethod.paramTypes = @[WSPR_PARAM_TYPE_STRING, WSPR_PARAM_TYPE_STRING];

    WSPRClassMethod *staticAppendMethod = [[WSPRClassMethod alloc] init];
    staticAppendMethod.mapName = @"append";
    staticAppendMethod.selector = @selector(appendString:withString:);
    staticAppendMethod.isVoidReturn = NO;
    staticAppendMethod.paramTypes = @[WSPR_PARAM_TYPE_STRING, WSPR_PARAM_TYPE_STRING];
    
    WSPRClassProperty *testProperty = [[WSPRClassProperty alloc] init];
    testProperty.mapName = @"testProperty";
    testProperty.keyPath = @"testProperty";
    testProperty.mode = WSPRPropertyModeReadWrite;
    testProperty.type = WSPR_PARAM_TYPE_STRING;

    WSPRClassProperty *testPassByReferenceProperty = [[WSPRClassProperty alloc] init];
    testPassByReferenceProperty.mapName = @"testPassByReferenceProperty";
    testPassByReferenceProperty.keyPath = @"testPassByReferenceProperty";
    testPassByReferenceProperty.mode = WSPRPropertyModeReadWrite;
    testPassByReferenceProperty.type = WSPR_PARAM_TYPE_INSTANCE;
    
    WSPRClassMethod *echoMethod = [[WSPRClassMethod alloc] init];
    echoMethod.mapName = @"echo";
    echoMethod.callBlock = ^(WSPRRemoteObjectController *rpcController, WSPRClassInstance *instance, WSPRClassMethod *theMethod, WSPRRequest *request){
        WSPRResponse *response = [request createResponse];
        response.result = request.params;
        request.responseBlock(response);
    };
    
    WSPRClassMethod *echoStringMethod = [[WSPRClassMethod alloc] init];
    echoStringMethod.mapName = @"echoString";
    echoStringMethod.paramTypes = @[WSPR_PARAM_TYPE_STRING];
    echoStringMethod.selector = @selector(echoString:);
    
    WSPRClassMethod *exceptionStaticMethod = [[WSPRClassMethod alloc] init];
    exceptionStaticMethod.mapName = @"exceptionInMethodCall";
    exceptionStaticMethod.selector = @selector(exceptionInMethodCall);
    
    WSPRClassMethod *exceptionMethod = [[WSPRClassMethod alloc] init];
    exceptionMethod.mapName = @"exceptionInMethodCall";
    exceptionMethod.selector = @selector(exceptionInMethodCall);
    
    WSPRClassMethod *staticPassByReferenceMethod = [[WSPRClassMethod alloc] init];
    staticPassByReferenceMethod.mapName = @"passByReference";
    staticPassByReferenceMethod.isVoidReturn = NO;
    staticPassByReferenceMethod.paramTypes = @[WSPR_PARAM_TYPE_INSTANCE];
    staticPassByReferenceMethod.selector = @selector(passByReference:);
    
    
    WSPRClassMethod *passByReferenceMethod = [[WSPRClassMethod alloc] init];
    passByReferenceMethod.mapName = @"passByReference";
    passByReferenceMethod.isVoidReturn = NO;
    passByReferenceMethod.paramTypes = @[WSPR_PARAM_TYPE_INSTANCE];
    passByReferenceMethod.selector = @selector(passByReference:);
    
    [classModel addStaticMethod:echoMethod];
    [classModel addStaticMethod:echoStringMethod];
    [classModel addStaticMethod:staticAppendMethod];
    [classModel addStaticMethod:exceptionStaticMethod];
    [classModel addStaticMethod:staticPassByReferenceMethod];
    [classModel addInstanceMethod:appendMethod];
    [classModel addInstanceMethod:exceptionMethod];
    [classModel addInstanceMethod:passByReferenceMethod];
    [classModel addProperty:testProperty];
    [classModel addProperty:testPassByReferenceProperty];
    
    return classModel;
}

+(NSString *)echoString:(NSString *)message
{
    return message;
}

-(NSString *)appendString:(NSString *)first withString:(NSString *)second
{
    return [first stringByAppendingString:second];
}

+(NSString *)appendString:(NSString *)first withString:(NSString *)second
{
    return [first stringByAppendingString:second];
}

+(void)exceptionInMethodCall
{
    NSException *exception = [NSException exceptionWithName:@"Test Exception" reason:@"Raised for test purposes" userInfo:nil];
    [exception raise];
}

-(void)exceptionInMethodCall
{
    NSException *exception = [NSException exceptionWithName:@"Test Exception" reason:@"Raised for test purposes" userInfo:nil];
    [exception raise];
}

+(NSString *)passByReference:(id<WSPRClassProtocol>)instance
{
    return [instance description];
}

-(NSString *)passByReference:(id<WSPRClassProtocol>)instance
{
    return [instance description];
}

@end
