//
//  LWXCache.h
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LWXCache : NSObject

/**
 初始化方法

 @param cacheDirectory 自定义的缓存路径
 */
- (nonnull instancetype)initWithCacheDirectory:(NSString* __nonnull)cacheDirectory;
+ (nonnull instancetype)globalCache;//初始化方法，使用默认的缓存路径

/**
 缓存保存事件，默认为1天
 */
@property(nonatomic) NSTimeInterval defaultTimeoutInterval;


/**
 获取对象key的剩余时间戳方法
 
 @param key 需要获取时间戳的数据的key
 
 @return 剩下的时间
 */
- (NSDate* __nullable)dateForKey:(NSString* __nonnull)key;



/**
 获取所有存储数据的key
 */
- (NSArray* __nonnull)allKeys;



/**
 缓存的删除和查找，以及清空

 @param key 需要删除和查找数据的key
 */
- (void)removeCacheForKey:(NSString* __nonnull)key;
- (BOOL)hasCacheForKey:(NSString* __nonnull)key;
- (void)clearCache;




/**
 NSData数据的读和写

 @param key 需要写入/写入数据的key

 @return 读取到的NSData
 */
- (NSData* __nullable)dataForKey:(NSString* __nonnull)key;
- (void)setData:(NSData* __nonnull)data forKey:(NSString* __nonnull)key;
- (void)setData:(NSData* __nonnull)data forKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;



/**
 NSString数据的读和写

 @param key 需要读/写数据的key

 @return 读取到的NSString
 */
- (NSString* __nullable)stringForKey:(NSString* __nonnull)key;
- (void)setString:(NSString* __nonnull)aString forKey:(NSString* __nonnull)key;
- (void)setString:(NSString* __nonnull)aString forKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;





/**
 UIImage数据的读和写
 
 @param key 需要读/写数据的key
 
 @return 读取到的UIImage
 */
- (UIImage* __nullable)imageForKey:(NSString* __nonnull)key;
- (void)setImage:(UIImage* __nonnull)anImage forKey:(NSString* __nonnull)key;
- (void)setImage:(UIImage* __nonnull)anImage forKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;



/**
 plist文件的读和写
 
 @param key 需要读/写数据的plist文件的文件名
 
 @return 读取到的plist文件
 */
- (NSData* __nullable)plistForKey:(NSString* __nonnull)key;
- (void)setPlist:(nonnull id)plistObject forKey:(NSString* __nonnull)key;
- (void)setPlist:(nonnull id)plistObject forKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;



/**
 对象数据的读和写
 
 @param key 需要读/写的对象
 
 @return 读取到的对象
 */
- (nullable id<NSCoding>)objectForKey:(NSString* __nonnull)key;
- (void)setObject:(nonnull id<NSCoding>)anObject forKey:(NSString* __nonnull)key;
- (void)setObject:(nonnull id<NSCoding>)anObject forKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;



/**
 文件的复制

 @param filePath 文件复制的目标路径
 @param key      文件赋值的其实路径的key
 */
- (void)copyFilePath:(NSString* __nonnull)filePath asKey:(NSString* __nonnull)key;
- (void)copyFilePath:(NSString* __nonnull)filePath asKey:(NSString* __nonnull)key withTimeoutInterval:(NSTimeInterval)timeoutInterval;




@end
