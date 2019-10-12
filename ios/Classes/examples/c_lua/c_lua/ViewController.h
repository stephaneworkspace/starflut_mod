//
//  ViewController.h
//  c_lua
//
//  Created by srplab on 14-9-30.
//  Copyright (c) 2014年 srplab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController


@end

@interface TestSRPClass : NSObject{
    NSString *_name;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *DoubleValue;
@property (nonatomic) NSInteger IntValue;

+(NSObject*)initTestSRPClass:(NSString *)initName;
-(id)usingPointer:(NSObject *)CleObject;

@end