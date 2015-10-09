//
//  WSPRPropertyBinder.m
//  Widespace-SDK-iOS
//
//  Created by Patrik Nyblad on 25/08/14.
//  Copyright (c) 2014 Widespace . All rights reserved.
//

#import "WSPRPropertyBinder.h"
@implementation WSPRPropertyBinding
-(NSString *)description
{
    return [@{
              @"target" : [NSString stringWithFormat:@"%p",_target],
              @"keyPath" : _keyPath ? : @""
              } description];
}
@end


@interface WSPRPropertyBinder()

@property (nonatomic, strong) NSArray *propertyBindings;
@property (nonatomic, strong) WSPRPropertyBinding *bindingBeingSet;

@end

@implementation WSPRPropertyBinder

-(NSArray *)propertyBindings
{
    if (!_propertyBindings)
        self.propertyBindings = [NSArray array];
    
    return _propertyBindings;
}

-(WSPRPropertyBinding *)addBindingForTarget:(NSObject *)target atKeyPath:(NSString *)keyPath
{
    return [self addBindingForTarget:target atKeyPath:keyPath transformSetValueBlock:nil];
}

-(WSPRPropertyBinding *)addBindingForTarget:(NSObject *)target atKeyPath:(NSString *)keyPath transformSetValueBlock:(id (^)(id))transformSetValueBlock
{
    WSPRPropertyBinding *propertyBinding = [[WSPRPropertyBinding alloc] init];
    propertyBinding.target = target;
    propertyBinding.keyPath = keyPath;
    propertyBinding.transformSetValueBlock = transformSetValueBlock;
    
    [target addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
    
    self.propertyBindings = [self.propertyBindings arrayByAddingObject:propertyBinding];
    return propertyBinding;
}

-(void)removeBinding:(WSPRPropertyBinding *)binding
{
    if ([self.propertyBindings containsObject:binding])
    {
        [binding.target removeObserver:self forKeyPath:binding.keyPath];
        NSMutableArray *propertyBindings = [NSMutableArray arrayWithArray:self.propertyBindings];
        [propertyBindings removeObject:binding];
        self.propertyBindings = [NSArray arrayWithArray:propertyBindings];
    }
}

-(void)removeAllBindings
{
    NSArray *copyOfBindings = [NSArray arrayWithArray:_propertyBindings];
    for (WSPRPropertyBinding *binding in copyOfBindings)
    {
        [self removeBinding:binding];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == _bindingBeingSet.target && [keyPath isEqualToString:_bindingBeingSet.keyPath])
        return;
        
    for (WSPRPropertyBinding *binding in self.propertyBindings)
    {
        if (binding.target == object && [binding.keyPath isEqualToString:keyPath])
            continue;
        
        id value = change[NSKeyValueChangeNewKey];
        if (binding.transformSetValueBlock)
            value = binding.transformSetValueBlock(value);
        
        self.bindingBeingSet = binding;
        [binding.target setValue:value forKeyPath:binding.keyPath];
        self.bindingBeingSet = nil;
    }
}

-(NSString *)description
{
    return [@{
              @"bindings" : _propertyBindings ? : @[]
              } description];
}

@end
