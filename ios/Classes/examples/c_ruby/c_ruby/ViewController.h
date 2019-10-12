//
//  ViewController.h
//  c_ruby
//
//  Created by srplab on 15/5/10.
//  Copyright (c) 2015年 srplab. All rights reserved.
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
-(id)usingPointer:(NSObject *)which;

@end