//
//  LWXHttpClient.h
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import "AFNetworking.h"

@interface LWXHttpClient : AFHTTPSessionManager



/**
 单例类

 @return 初始化方法
 */
+(instancetype)sharedHTTPClient;

/**
 *  是否连接网络
 * */
-(BOOL)isReachable;

@end
