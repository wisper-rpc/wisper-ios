//
//  WSPRHelper.h
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 11/06/14.
//  Copyright (c) 2014 Widespace . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WSPRClassMethod.h"

typedef enum {
    WSPRCallTypeUnknown,
    WSPRCallTypeCreate,
    WSPRCallTypeDestroy,
    WSPRCallTypeStatic,
    WSPRCallTypeStaticEvent,
    WSPRCallTypeInstance,
    WSPRCallTypeInstanceEvent
} WSPRCallType;


/**
 Helper class designed to maintain functions that parses and validates various Wisper related objects.
 This class should only have static methods and can be used by all other RPC classes.
 */
@interface WSPRHelper : NSObject

/**
 Compares if the argument passed is of the matching param type.
 @param paramType A string representing a valid Wisper param type.
 ###Use one of the constants:###
 * WSPR_PARAM_TYPE_STRING
 * WSPR_PARAM_TYPE_NUMBER
 * WSPR_PARAM_TYPE_ARRAY
 * WSPR_PARAM_TYPE_DICTIONARY
 
 @param argument An object passed as the argument to some Wisper method. This objects class will be
 checked agains the class mathing ont of the paramType strings.

 @return YES if argument is same kind or subclass of paramType.
 */
+(BOOL)paramType:(NSString *)paramType matchesArgument:(id)argument;

/**
 Parses the intended call type from the passed method string
 @param method The full method string.
 @return A call type representing what the method tries to accomplish.
 */
+(WSPRCallType)callTypeFromMethodString:(NSString *)method;

/**
 Parses the class name from the method string.
 ex. "wisp.ai.Video:~" gives us "wisp.ai.Video".
 @param method The full method string.
 @return A string representing the intended class to be called.
 */
+(NSString *)classNameFromMethodString:(NSString *)method;

/**
 Parses the method name from the method string.
 ex. "wisp.ai.Video:play" gives us "play".
 @param method The full method string.
 @return A string representing the intended method to be called.
 */
+(NSString *)methodNameFromMethodString:(NSString *)method;

/**
 Gives you all components of the method ex. "wisp.ctrl.getEndAction" = ["wisp", "ctrl", "getEndAction"]
 ex. "wisp.ai.Awesome:test" = ["wisp", "ai", "Awesome", "test"]
 @param method The full method string
 @return Array containing all separated components based on "." and ":".
 */
+(NSArray *)methodComponentsFromMethodString:(NSString *)method;

/**
 Gives you all components of the method ex. "wisp.ctrl.getEndAction" = [".", "."]
 ex. "wisp.ai.Awesome:test" = [".", ".", ":"]
 @param method The full method string
 @return Array containing all separators between the components based on "." and ":".
 */
+(NSArray *)methodComponentSeparatorsFromMethodString:(NSString *)method;

/**
 Returns an object that is safe for using in JSON serialization.
 @param object Any subclass of NSObject, if its a collection the whole collection will be processed recursively.
 @return An object safe for usage in JSON serialization.
 */
+(id)jsonSafeObjectFromObject:(NSObject *)object;

/**
 Parses a json string into either a Dictionary or an Array. This method captures parsing exceptions and tries to make the operation as safe as possible.
 @param jsonString A string carrying valid json.
 @param completion A block that will be called synchronously with the parsing result.
 */
+(void)objectFromJSONString:(NSString *)jsonString completion:(void (^)(NSDictionary *jsonDict, NSArray *jsonArray, NSError *error))completion;

/**
 Serializes an object (NSDictionary or NSArray) to a json string. This method captures parsing exceptions, converts NSSet to array and NSDate to epoch number. 
 This method tries to make the serialization operation as safe as possible.
 @param object An NSDictionary or NSArray instance to serialize to a JSON string.
 @param completion A block that will be called synchronously with the parsing result.
 */
+(void)jsonStringFromObject:(NSObject *)object completion:(void(^)(NSString *jsonString, NSError *error))completion;

@end
