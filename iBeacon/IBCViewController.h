//
//  IBCViewController.h
//  iBeacon
//
//  Created by 羽田 健太郎 on 2013/12/01.
//  Copyright (c) 2013年 羽田 健太郎. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h> 
#import "IBCCommon.h"

@interface IBCViewController : UIViewController<CLLocationManagerDelegate>{
    IBOutlet UILabel* statusLbl;
    IBOutlet UILabel* messageLbl;
    IBOutlet UILabel* kitakuTimeLbl;
    IBOutlet UILabel* regionLbl;
}


@end
