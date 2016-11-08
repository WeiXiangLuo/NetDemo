//
//  LWXNetRequest.h
//  NetDemo
//
//  Created by lwx on 2016/11/8.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 HTTP访问回调
 
 @param stateCode 状态码 0 访问失败   200 正常  500 空 其他异常
 @param result    返回数据 nil 为空
 @param error     错误描述
 */
typedef void(^LWXResultBlock)(NSInteger stateCode, NSMutableArray* result, NSError *error);


@interface LWXNetRequest : NSObject

/**
 普通的访问请求(有提示，带判断网络状态)

 @param URLString    接口地址
 @param parameters   字典参数
 @param requestBlock 回调函数
 */
+ (void)GET:(NSString *)URLString parameters:(id)parameters result:(LWXResultBlock)requestBlock;
+ (void)POST:(NSString *)URLString  parameters:(id)parameters result:(LWXResultBlock)requestBlock;

/**
 *  普通的访问请求(无提示，不带判断网络状态)
 *
 *  @param URLString    接口地址
 *  @param parameters   字典参数
 *  @param requestBlock 回调函数
 */
+ (void)GETWithNormal:(NSString *)URLString  parameters:(id)parameters result:(LWXResultBlock)requestBlock;
+ (void)POSTWithNormal:(NSString *)URLString  parameters:(id)parameters result:(LWXResultBlock)requestBlock;

/**
 带缓存的访问请求
 
 @param URLString    接口地址
 @param parameters   字典参数
 @param isShow       是否显示提示
 @param requestBlock 请求回调函数
 @param cacheBlock   缓存回调函数
 */
+ (void)GETWithCache:(NSString *)URLString parameters:(id)parameters  isShow:(BOOL)isShow result:(LWXResultBlock)requestBlock cacheBlock:(LWXResultBlock)cacheBlock;
+ (void)POSTWithCache:(NSString *)URLString parameters:(id)parameters isShow:(BOOL)isShow  result:(LWXResultBlock)requestBlock cacheBlock:(LWXResultBlock)cacheBlock;


/**
 *  上传多媒体文件接口
 *
 *  @param URLString    请求地址
 *  @param parameters   请求参数
 *  @param mediaDatas   多媒体数据  图片传 UIImage  语音传url字符串地址
 *  @param requestBlock 请求回调
 */
+(void)POSTWithFormDataURL:(NSString *)URLString parameters:(id)parameters mediaData:(NSMutableArray *)mediaDatas completionBlock:(LWXResultBlock)requestBlock;


@end
