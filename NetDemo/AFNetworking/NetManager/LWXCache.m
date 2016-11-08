//
//  LWXCache.m
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import "LWXCache.h"

#if DEBUG
#	define CHECK_FOR_EGOCACHE_PLIST() if([key isEqualToString:@"LWXCache.plist"]) { \
NSLog(@"LWXCache.plist is a reserved key and can not be modified."); \
return; }
#else
#	define CHECK_FOR_EGOCACHE_PLIST() if([key isEqualToString:@"LWXCache.plist"]) return;
#endif

#if !__has_feature(nullability)
#	define nullable
#	define nonnull
#	define __nullable
#	define __nonnull
#endif


static inline NSString* cachePathForKey(NSString* directory, NSString* key) {
    key = [key stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [directory stringByAppendingPathComponent:key];
}

@interface LWXCache () {
    dispatch_queue_t        _cacheInfoQueue;//缓存信息队列
    dispatch_queue_t        _frozenCacheInfoQueue;//过时时间缓存信息队列
    dispatch_queue_t        _diskQueue;//硬盘缓存队列
    NSMutableDictionary    *_cacheInfo;//缓存字典
    NSString               *_directory;//硬盘路径
    BOOL                    _needsSave;//是否保存标记
}

@property(nonatomic,copy) NSDictionary* frozenCacheInfo;//过时缓存字典

@end


static char *cacheInfoQueueName = "com.lwx.lwxcache.info";
static char *frozenCacheInfoQueueName = "com.lwx.lwxcache.info.frozen";
static char *diskQueueName = "com.lwx.lwxcache.disk";

@implementation LWXCache


#pragma mark - 初始化方法
+ (instancetype)globalCache {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}


- (instancetype)init {
    //获取沙盒路劲
    //设置默认缓存路径
    NSString* cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString* oldCachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"LWXCache"] copy];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:oldCachesDirectory]) {
        [[NSFileManager defaultManager] removeItemAtPath:oldCachesDirectory error:NULL];
    }
    
    cachesDirectory = [[[cachesDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:@"LWXCache"] copy];
    return [self initWithCacheDirectory:cachesDirectory];
}


- (instancetype)initWithCacheDirectory:(NSString*)cacheDirectory {
    if((self = [super init])) {
        //创建缓存信息队列
        _cacheInfoQueue             = dispatch_queue_create(cacheInfoQueueName, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t priority   = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(priority, _cacheInfoQueue);
        
        //创建过时缓存信息队列
        _frozenCacheInfoQueue       = dispatch_queue_create(frozenCacheInfoQueueName, DISPATCH_QUEUE_SERIAL);
        priority                    = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(priority, _frozenCacheInfoQueue);
        
        _diskQueue                  = dispatch_queue_create(diskQueueName, DISPATCH_QUEUE_CONCURRENT);
        priority                    = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_set_target_queue(priority, _diskQueue);
        
        
        _directory                  = cacheDirectory;
        
        //初始化缓存字典，追加本地缓存文件路径
        _cacheInfo                  = [[NSDictionary dictionaryWithContentsOfFile:cachePathForKey(_directory, @"LWXCache.plist")] mutableCopy];
        
        //懒加载初始化缓存字典
        if(!_cacheInfo) {
            _cacheInfo                  = [[NSMutableDictionary alloc] init];
        }
        
        //根据路径创建文件
        [[NSFileManager defaultManager] createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        //追加时间戳
        NSTimeInterval now          = [[NSDate date] timeIntervalSinceReferenceDate];
        NSMutableArray* removedKeys = [[NSMutableArray alloc] init];
        
        //遍历缓存字典，移除掉过时文件
        for(NSString* key in _cacheInfo) {
            if([_cacheInfo[key] timeIntervalSinceReferenceDate] <= now) {
                [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
                [removedKeys addObject:key];
            }
        }
        
        //从字典中移除掉过时文件
        [_cacheInfo removeObjectsForKeys:removedKeys];
        //给过时缓存信息字典全局变量赋值
        self.frozenCacheInfo        = _cacheInfo;
        //设置默认缓存事件为1天
        [self setDefaultTimeoutInterval:86400];
    }
    
    return self;
}




#pragma mark - 数据方法
#pragma mark - 获得所有键
- (NSArray*)allKeys {
    __block NSArray* keys = nil;
    
    dispatch_sync(_frozenCacheInfoQueue, ^{
        keys = [self.frozenCacheInfo allKeys];
    });
    
    return keys;
}

#pragma mark 清理缓存
- (void)clearCache {
    
    dispatch_sync(_cacheInfoQueue, ^{
        //从硬盘中清理数据
        for(NSString* key in _cacheInfo) {
            [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
        }
        
        //从字典中清理数据
        [_cacheInfo removeAllObjects];
        
        
        //过时缓存也清理掉
        dispatch_sync(_frozenCacheInfoQueue, ^{
            self.frozenCacheInfo = [_cacheInfo copy];
        });
        
        [self setNeedsSave];
    });
    
}


#pragma mark 是否保存数据
- (void)setNeedsSave {
    
    dispatch_async(_cacheInfoQueue, ^{
        
        //需要保存，直接退出
        if(_needsSave) {
            
            return;
        }
        //否则，将缓存字典写入本地
        _needsSave = YES;
        
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, _cacheInfoQueue, ^(void){
            if(!_needsSave) return;
            [_cacheInfo writeToFile:cachePathForKey(_directory, @"LWXCache.plist") atomically:YES];
            _needsSave = NO;
        });
    });
}


#pragma mark - 删除
- (void)removeCacheForKey:(NSString*)key {
    CHECK_FOR_EGOCACHE_PLIST();
    
    //从沙盒中移除该key
    dispatch_async(_diskQueue, ^{
        [[NSFileManager defaultManager] removeItemAtPath:cachePathForKey(_directory, key) error:NULL];
    });
    
    //设置其剩余时间戳为0
    [self setCacheTimeoutInterval:0 forKey:key];
}

#pragma mark 查询数据
- (BOOL)hasCacheForKey:(NSString*)key {
    //获得该key的时间戳
    NSDate* date = [self dateForKey:key];
    
    //没有则没有该数据
    if(date == nil) {
        return NO;
    }
    
    //判断时间是否小于当前时间，小于则已经过时，返回NO
    if([date timeIntervalSinceReferenceDate] < CFAbsoluteTimeGetCurrent()) {
        return NO;
    }
    
    //从本地沙盒查找是否存在该数据
    return [[NSFileManager defaultManager] fileExistsAtPath:cachePathForKey(_directory, key)];
}


#pragma mark - 修改数据剩下保存的时间
- (void)setCacheTimeoutInterval:(NSTimeInterval)timeoutInterval forKey:(NSString*)key {
    
    //将时间戳改为NSDate
    NSDate* date = timeoutInterval > 0 ? [NSDate dateWithTimeIntervalSinceNow:timeoutInterval] : nil;
    
    //将时间戳写入保存时间的字典中
    dispatch_sync(_frozenCacheInfoQueue, ^{
        NSMutableDictionary* info = [self.frozenCacheInfo mutableCopy];
        
        //设置时间为新时间戳，否则移除该key
        if(date) {
            info[key] = date;
        } else {
            [info removeObjectForKey:key];
        }
        
        self.frozenCacheInfo = info;
    });
    
    //将时间戳保存到缓存字典中
    dispatch_async(_cacheInfoQueue, ^{
        //设置时间为新时间戳，否则移除该key
        if(date) {
            _cacheInfo[key] = date;
        } else {
            [_cacheInfo removeObjectForKey:key];
        }
        
        dispatch_sync(_frozenCacheInfoQueue, ^{
            self.frozenCacheInfo = [_cacheInfo copy];
        });
        
        //重新将新文件写入本地
        [self setNeedsSave];
    });
}




#pragma mark - 获取对应数据key的时间戳
- (NSDate*)dateForKey:(NSString*)key {
    __block NSDate* date = nil;
    
    //从字典中取出该NSDate时间
    dispatch_sync(_frozenCacheInfoQueue, ^{
        date = (self.frozenCacheInfo)[key];
    });
    
    return date;
}


#pragma mark - NSData的读和写
- (NSData*)dataForKey:(NSString*)key {
    //判断是否有该key
    if([self hasCacheForKey:key]) {
        //有，则从沙盒取出文件，转化为NSData文件返回
        return [NSData dataWithContentsOfFile:cachePathForKey(_directory, key) options:0 error:NULL];
    } else {
        return nil;
    }
}


- (void)setData:(NSData*)data forKey:(NSString*)key {
    [self setData:data forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}


- (void)setData:(NSData*)data forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    CHECK_FOR_EGOCACHE_PLIST();
    //获取本地路径
    NSString* cachePath = cachePathForKey(_directory, key);
    
    //写入本地
    dispatch_async(_diskQueue, ^{
        [data writeToFile:cachePath atomically:YES];
    });
    
    //设置时间戳保存时间
    [self setCacheTimeoutInterval:timeoutInterval forKey:key];
}


#pragma mark - String的读和写
- (NSString*)stringForKey:(NSString*)key {
    return [[NSString alloc] initWithData:[self dataForKey:key] encoding:NSUTF8StringEncoding];
}

- (void)setString:(NSString*)aString forKey:(NSString*)key {
    [self setString:aString forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setString:(NSString*)aString forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [self setData:[aString dataUsingEncoding:NSUTF8StringEncoding] forKey:key withTimeoutInterval:timeoutInterval];
}

#pragma mark - Image的读和写
- (UIImage*)imageForKey:(NSString*)key {
    UIImage* image = nil;
    
    @try {
        //获取UIImage
        image = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePathForKey(_directory, key)];
    } @catch (NSException* e) {
        
    }
    
    return image;
}


- (void)setImage:(UIImage*)anImage forKey:(NSString*)key {
    [self setImage:anImage forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setImage:(UIImage*)anImage forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    @try {
        //使用NSKeyedArchiver可以保存图片的所有信息
        [self setData:[NSKeyedArchiver archivedDataWithRootObject:anImage] forKey:key withTimeoutInterval:timeoutInterval];
    } @catch (NSException* e) {
        
    }
}

#pragma mark - plist文件的读和写
- (NSData*)plistForKey:(NSString*)key; {
    //读取到XML文件
    NSData* plistData = [self dataForKey:key];
    //解析成plist文件
    return [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:nil error:nil];
}

- (void)setPlist:(id)plistObject forKey:(NSString*)key; {
    [self setPlist:plistObject forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setPlist:(id)plistObject forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval; {
    //将plist文件转化为XML文件
    NSData* plistData = [NSPropertyListSerialization dataWithPropertyList:plistObject format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    
    if(plistData != nil) {
        [self setData:plistData forKey:key withTimeoutInterval:timeoutInterval];
    }
}


#pragma mark - 对象文件的读和写
- (id<NSCoding>)objectForKey:(NSString*)key {
    if([self hasCacheForKey:key]) {
        //反序列化对象
        return [NSKeyedUnarchiver unarchiveObjectWithData:[self dataForKey:key]];
    } else {
        return nil;
    }
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString*)key {
    [self setObject:anObject forKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    //对象序列化
    [self setData:[NSKeyedArchiver archivedDataWithRootObject:anObject] forKey:key withTimeoutInterval:timeoutInterval];
}



#pragma mark - 赋值文件方法
- (void)copyFilePath:(NSString*)filePath asKey:(NSString*)key {
    [self copyFilePath:filePath asKey:key withTimeoutInterval:self.defaultTimeoutInterval];
}

- (void)copyFilePath:(NSString*)filePath asKey:(NSString*)key withTimeoutInterval:(NSTimeInterval)timeoutInterval {
    dispatch_async(_diskQueue, ^{
        //复制文件到当前filePath
        [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:cachePathForKey(_directory, key) error:NULL];
    });
    
    [self setCacheTimeoutInterval:timeoutInterval forKey:key];
}



@end
