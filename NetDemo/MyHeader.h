//
//  MyHeader.h
//  WeChatDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#ifndef MyHeader_h
#define MyHeader_h

#import <Foundation/Foundation.h>



//微信授权信息
static NSString *appKey = @"1603987027";
static NSString *appSecret = @"7765fda533ad2c0905eeb56436a96eca";

#define BaseURL     @"https://api.weibo.com/"
#define LoginURL    [NSString stringWithFormat:@"%@oauth2/authorize",BaseURL]


//屏幕尺寸
#define kMainB      [UIScreen mainScreen].bounds
#define kMainWidth  kMainB.size.width
#define kMainHeight kMainB.size.height

//NSLog输出
#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif



















#endif /* MyHeader_h */
