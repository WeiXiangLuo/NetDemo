//
//  LWXNetRequest.m
//  NetDemo
//
//  Created by lwx on 2016/11/8.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import "LWXNetRequest.h"
#import "LWXHttpClient.h"
#import "LWXBaseModel.h"
#import "LWXCache.h"
#import "TSMessage.h"
#import "MJExtension.h"
#import "NSObject+JSonArray.h"
#import "NSDictionary+String.h"


#define REQUEST_ERROR(aCode)    (aCode==-1009?@"没连接网络呢":@"服务器在偷懒!")
#define DATA_ERROR     @"服务器正在打瞌睡哦，稍后重试吧"

/**
 *  接口回调
 *
 *  @param result    返回数据
 *  @param errorCode 错误码
 *  @param message   错误代码
 */
typedef void(^ServerBlock)(id result, NSInteger errorCode, NSString *message);


@implementation LWXNetRequest


#pragma mark - 有提示有网络判断的请求
+ (void)GET:(NSString *)URLString parameters:(id)parameters result:(LWXResultBlock)requestBlock {
    
    if ([LWXHttpClient sharedHTTPClient].isReachable) { //如果有网络
        
        [self GETWithNormal:URLString parameters:parameters result:requestBlock];
        
    } else {
        
        [self showMessage:0];
        if (requestBlock) {
            requestBlock(0,nil,nil);
        }
    }
}


+ (void)POST:(NSString *)URLString parameters:(id)parameters result:(LWXResultBlock)requestBlock {
    
    if ([LWXHttpClient sharedHTTPClient].isReachable) {//如果有网络
        
        [self POSTWithNormal:URLString parameters:parameters result:requestBlock];
        
    }else{
        [self showMessage:0];
        if (requestBlock) {
            requestBlock(0,nil,nil);
        }
    }
    
    
}


#pragma mark - 无提示无网络判断的请求
+ (void)GETWithNormal:(NSString *)URLString parameters:(id)parameters result:(LWXResultBlock)requestBlock {
    
    //AF请求
    [[LWXHttpClient sharedHTTPClient] GET:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (requestBlock) {
            //MJ解析
            LWXBaseModel *model = [LWXBaseModel mj_objectWithKeyValues:responseObject];
            requestBlock(model.state,[model.result jsonBase64Value],nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [self showMessage:[error code]];
        if (requestBlock) {
            requestBlock(0,nil,error);
        }
        
    }];
    
}

+ (void)POSTWithNormal:(NSString *)URLString parameters:(id)parameters result:(LWXResultBlock)requestBlock {
    
    [[LWXHttpClient sharedHTTPClient] POST:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (requestBlock) {
            LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
            requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (requestBlock) {
            requestBlock(0,nil,error);
        }
    }];

}


#pragma mark - 带缓存的有提示有网络判断的请求
+ (void)GETWithCache:(NSString *)URLString parameters:(id)parameters isShow:(BOOL)isShow result:(LWXResultBlock)requestBlock cacheBlock:(LWXResultBlock)cacheBlock {
    
    //将parameters转化为NSString
    NSString *urlStr = (parameters == nil ? URLString : [URLString stringByAppendingString: [parameters urlQueryString]]);
    id responseObject = [[LWXCache globalCache] objectForKey:urlStr];
    
    //如果实现了缓存block
    if (cacheBlock) {
        if (responseObject) {
            LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
            cacheBlock(0,[baseModel.result jsonBase64Value],nil);
            
        }else{
            cacheBlock(0,nil,nil);
        }
    }

    
    if ([LWXHttpClient sharedHTTPClient].isReachable) {
        [[LWXHttpClient sharedHTTPClient] GET:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (responseObject) {
                //保存数据
                [[LWXCache globalCache] setObject:responseObject forKey:urlStr];
            } else {//没有拿到数据，将缓存数据返回
                
                if (requestBlock && responseObject) {//没有请求到东西，直接返回
                    LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                    requestBlock(0,[baseModel.result jsonBase64Value],nil);
                    return ;
                }
            }
            
            //拿到Json数据返回
            if (requestBlock) {
                LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (isShow) {
                [self showMessage:[error code]];
            }
            
            //如果实现了block
            if (requestBlock) {
                //如果缓存中有数据
                if (responseObject) {
                    LWXBaseModel *baseModel = [LWXBaseModel mj_objectWithKeyValues:responseObject];
                    requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
                    
                }else{
                    requestBlock(0,nil,nil);
                }
            }
            
        }];
    } else { //没有网络
        
        if (isShow) {
            [self showMessage:0];
        }
        
        
        if (requestBlock) {
            if (responseObject) {
                LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                requestBlock(0,[baseModel.result jsonBase64Value],nil);
            }else{
                requestBlock(0,nil,nil);
            }
        }
    }
    
    
}


+ (void)POSTWithCache:(NSString *)URLString parameters:(id)parameters isShow:(BOOL)isShow result:(LWXResultBlock)requestBlock cacheBlock:(LWXResultBlock)cacheBlock{
    
    //将parameters转化为NSString
    NSString *urlStr =[URLString stringByAppendingString: [parameters urlQueryString]];
    id responseObject = [[LWXCache globalCache] objectForKey:urlStr];
    
    //如果实现了缓存block
    if (cacheBlock) {
        if (responseObject) {
            LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
            cacheBlock(0,[baseModel.result jsonBase64Value],nil);
            
        }else{
            cacheBlock(0,nil,nil);
        }
    }
    
    if ([LWXHttpClient sharedHTTPClient].isReachable) {//有网络
        
        [[LWXHttpClient sharedHTTPClient] POST:URLString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            if (responseObject) {
                //保存数据
                [[LWXCache globalCache] setObject:responseObject forKey:urlStr];
            } else {//没有拿到数据，将缓存数据返回
                
                if (requestBlock && responseObject) {//没有请求到东西，直接返回
                    LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                    requestBlock(0,[baseModel.result jsonBase64Value],nil);
                    return ;
                }
            }
            
            //拿到Json数据返回
            if (requestBlock) {
                LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {

            if (isShow) {
                [self showMessage:[error code]];
            }
            
            //如果实现了block
            if (requestBlock) {
                //如果缓存中有数据
                if (responseObject) {
                    LWXBaseModel *baseModel = [LWXBaseModel mj_objectWithKeyValues:responseObject];
                    requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
                    
                }else{
                    requestBlock(0,nil,nil);
                }
            }
            
        }];
    } else { //没有网络

        if (isShow) {
            [self showMessage:0];
        }

        
        if (requestBlock) {
            if (responseObject) {
                LWXBaseModel *baseModel=[LWXBaseModel mj_objectWithKeyValues:responseObject];
                requestBlock(0,[baseModel.result jsonBase64Value],nil);
            }else{
                requestBlock(0,nil,nil);
            }
        }
    }
}




#pragma mark - 多媒体上传接口
+ (void)POSTWithFormDataURL:(NSString *)URLString parameters:(id)parameters mediaData:(NSMutableArray *)mediaDatas
           completionBlock:(LWXResultBlock)requestBlock{
    
    //AF请求
    [[LWXHttpClient sharedHTTPClient] POST:URLString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //遍历数据数组
        for(NSInteger i = 0; i < mediaDatas.count; i++) {
            
            NSObject *firstObj = [mediaDatas objectAtIndex:i];
            
            if ([firstObj isKindOfClass:[UIImage class]]) { // 图片
                UIImage *eachImg = [mediaDatas objectAtIndex:i];
                
                NSData *eachImgData = UIImageJPEGRepresentation(eachImg, 0.5);//设置压缩率
                
                //上传接口调用
                [formData appendPartWithFileData:eachImgData name:@"file" fileName:[NSString stringWithFormat:@"img%d.jpg", (int)i+1] mimeType:@"image/jpeg"];
                
            }else if ([firstObj isKindOfClass:[NSString class]]) {//如果是字符串
                
                NSURL *mediaUrl = [NSURL URLWithString:[mediaDatas objectAtIndex:i]]; //获得路径
                
                NSData *mediaData=[[NSData alloc]initWithContentsOfFile:mediaUrl.absoluteString];//通过路径获得多媒体数据
                
                //上传接口调用
                [formData appendPartWithFileData:mediaData name:@"file" fileName:[NSString stringWithFormat:@"%d.mp3", (int)i+1] mimeType:@"audio/mpeg3"];
            }
        }
        
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        
        if (requestBlock) {
            LWXBaseModel *baseModel = [LWXBaseModel mj_objectWithKeyValues:responseObject];
            requestBlock(baseModel.state,[baseModel.result jsonBase64Value],nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (requestBlock) {
            requestBlock(0,nil,error);
        }
    }];
}





#pragma mark - 内部方法，无法连接提示
+ (void)showMessage:(NSInteger)code {
    
    NSString *subTitle = @"尝试连接网络,并重试";
    if (code != -1009) {
        subTitle = @"您的服务器被程序猿搬走了,稍后重试吧";
    }
    
    [TSMessage showNotificationWithTitle:REQUEST_ERROR(code) subtitle:subTitle type:TSMessageNotificationTypeWarning];
    
}




@end
