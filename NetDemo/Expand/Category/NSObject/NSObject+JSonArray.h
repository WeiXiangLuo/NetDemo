//
//  NSObject+JSonArray.h
//  NetDemo
//
//  Created by lwx on 2016/11/8.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JSonArray)
/**
 * 将Base64Json基类转为Json字典
 */
- (id)jsonBase64Value;

+ (NSMutableArray*)macObjectToArray;

@end
