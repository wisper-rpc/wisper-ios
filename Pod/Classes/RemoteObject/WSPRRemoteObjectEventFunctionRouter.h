//
//  WSPRRemoteObjectEventFunctionRouter.h
//  Pods
//
//  Created by Patrik Nyblad on 24/03/16.
//
//

#import "WSPRFunctionRouter.h"
#import "WSPRRemoteObject.h"

@interface WSPRRemoteObjectEventFunctionRouter : WSPRFunctionRouter

@property (nonatomic, assign) Class<WSPRRemoteObjectEventProtocol> remoteObjectClass;

-(instancetype)initWithRemoteObjectClass:(Class<WSPRRemoteObjectEventProtocol>)remoteObjectClass;

/**
 *  Add a remote object to this router so that it can get instance / class events forwarded
 *  @param remoteObject The remote object that should receive events.
 *  @warning This will not retain the remote object to allow you to destroy the object by just removing your strong references to it. Remember to unregister the remote object when it is being deallocated.
 */
-(void)registerRemoteObjectInstance:(WSPRRemoteObject *)remoteObject;

/**
 *  Remove a remote object from this router so that it no longer receives events.
 *  @param remoteObject The remote object that should no longer receive events.
 *  @warning Remember to unregister your object when deallocating it to avoid dangling pointers.
 */
-(void)unregisterRemoteObjectInstance:(WSPRRemoteObject *)remoteObject;

@end
