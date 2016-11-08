//
//  LWXBaseModel.h
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LWXBaseModel : NSObject

/**
 *  状态码
 */
@property(nonatomic,assign)NSInteger state;

/**
 *  返回的Result参数集合
 */
@property(nonatomic,strong) NSObject *result;


@end
