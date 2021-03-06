//
//  WSPRInstanceRegistry.h
//  Pods
//
//  Created by Patrik Nyblad on 15/02/16.
//
//

#import <Foundation/Foundation.h>
#import "WSPRClassInstance.h"
#import "WSPRRouter.h"

/**
 *  Handles collections of instances. All instances are kept here and grouped under different root routers.
 */
@interface WSPRInstanceRegistry : NSObject

/**
 *  Singelton accessor.
 *  @return The shared instance.
 */
+(instancetype)sharedInstance;

/**
 *  Get a full dictionary of instances under a specific root route. The key is the instance identifier for each instance.
 *
 *  @param rootRoute The root route scope.
 *
 *  @return A dictionary of instances if any have been added.
 */
+(NSMutableDictionary *)instancesUnderRootRoute:(id<WSPRRouteProtocol>)rootRoute;

/**
 *  Get an instance by providing its instance identifier
 *
 *  @param identifier The identifier of the instance we want to get.
 *  @param rootRoute  What root route this is available under.
 *
 *  @return The requested instance or nil if not available.
 */
+(WSPRClassInstance *)instanceWithId:(NSString *)identifier underRootRoute:(id<WSPRRouteProtocol>)rootRoute;

/**
 *  Get a wisper instance by passing the actual instance.
 *
 *  @param instance  The actual instance we want the model for.
 *  @param rootRoute The root route where we are are searching for the instance.
 *
 *  @return An instance wrapper model if found, otherwise nil.
 */
+(WSPRClassInstance *)instanceModelForInstance:(id<WSPRClassProtocol>)instance underRootRoute:(id<WSPRRouteProtocol>)rootRoute;

/**
 *  Add an instance scoped under a specific root route.
 *
 *  @param instance  The instance you want to add.
 *  @param rootRoute The root route to scope the instance life cycle under.
 */
+(void)addInstance:(WSPRClassInstance *)instance underRootRoute:(id<WSPRRouteProtocol>)rootRoute;

/**
 *  Remove an instance scoped under a specific root route.
 *
 *  @param instance  The instance you want to remove.
 *  @param rootRoute The root route which this instance is scoped under.
 */
+(void)removeInstance:(WSPRClassInstance *)instance underRootRoute:(id<WSPRRouteProtocol>)rootRoute;

/**
 *  Removes an instance regardless of knowing the root route.
 *
 *  @param instance The instance you want to remove.
 */
+(void)forceRemoveInstance:(WSPRClassInstance *)instance;

/**
 *  Removes any instances with the passed identifier under all root route domains.
 *  If all instances (no matter the domain) have unique Ids. 
 *
 *  @param identifier The identifier of the instance you want to remove.
 */
+(void)forceRemoveInstanceWithId:(NSString *)identifier;

/**
 *  Flushes all instances registered under a root route.
 *
 *  @param rootRoute The root route you want to flush all instances for.
 */
+(void)flushInstancesUnderRootRoute:(id<WSPRRouteProtocol>)rootRoute;


@end
