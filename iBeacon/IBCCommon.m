//
//  IBCCommon.m
//  iBeacon
//
//  Created by 羽田 健太郎 on 2013/12/01.
//  Copyright (c) 2013年 羽田 健太郎. All rights reserved.
//

#import "IBCCommon.h"

@implementation IBCCommon

+(NSString*)getConnectionStatus{
    Reachability *reachablity = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachablity currentReachabilityStatus];
    NSString* connectStr = @"none";
    
    switch (status) {
        case NotReachable:
            connectStr = @"接続されてません";
            break;
        case ReachableViaWWAN:
            connectStr = @"3G接続";
            break;
        case ReachableViaWiFi:
            connectStr = @"Wifi接続中";
            break;
        default:
            break;
    }
    return connectStr;
}

@end
