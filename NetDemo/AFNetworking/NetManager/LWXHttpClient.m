//
//  LWXHttpClient.m
//  NetDemo
//
//  Created by lwx on 2016/11/7.
//  Copyright © 2016年 lwx. All rights reserved.
//

#import "LWXHttpClient.h"
#import "MyHeader.h"

@interface LWXHttpClient ()

@end


@implementation LWXHttpClient

static LWXHttpClient *_sharedHTTPClient = nil;

static NSString *baseUrl = @"http://www.baidu.com";



+ (instancetype)sharedHTTPClient {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initHTTPClient];
        
    });
    
    return _sharedHTTPClient;
}


+ (void)initHTTPClient{
        
    _sharedHTTPClient = [[LWXHttpClient alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
    [_sharedHTTPClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
                DLog(@"-------AFNetworkReachabilityStatusReachableViaWWAN------");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                DLog(@"-------AFNetworkReachabilityStatusReachableViaWiFi------");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                DLog(@"-------AFNetworkReachabilityStatusNotReachable------");
                break;
            default:
                break;
        }
    }];
    [_sharedHTTPClient.reachabilityManager startMonitoring];
}

- (BOOL)isReachable{

    return YES;
//    return [_sharedHTTPClient.reachabilityManager isReachable];
    
}

-(instancetype)initWithBaseURL:(nullable NSURL *)url{
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
    self.requestSerializer                         = [AFHTTPRequestSerializer serializer];
    self.responseSerializer                        = [AFHTTPResponseSerializer serializer];
    self.requestSerializer.timeoutInterval         = 10.0;
    AFSecurityPolicy *securityPolicy               = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    securityPolicy.allowInvalidCertificates        = YES;
    
    securityPolicy.validatesDomainName             = NO;
    self.securityPolicy                            = securityPolicy;
    return self;
}


@end
