//
//  ViewController.m
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import "ViewController.h"
#import "LWXNetRequest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [LWXNetRequest GETWithCache:@"http://www.baidu.com" parameters:nil isShow:YES result:^(NSInteger stateCode, NSMutableArray *result, NSError *error) {
        NSLog(@"%@",result);
    } cacheBlock:^(NSInteger stateCode, NSMutableArray *result, NSError *error) {
        NSLog(@"%@",result);
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
