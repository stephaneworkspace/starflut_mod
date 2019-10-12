//
//  ViewController.h
//  c_python
//
//  Created by srplab on 12-7-8.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
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