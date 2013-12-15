//
//  IBCCommon.h
//  iBeacon
//
//  Created by 羽田 健太郎 on 2013/12/01.
//  Copyright (c) 2013年 羽田 健太郎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"

@interface IBCCommon : NSObject
+(NSString*)getConnectionStatus;

@end
