//
//  IBCViewController.m
//  iBeacon
//
//  Created by 羽田 健太郎 on 2013/12/01.
//  Copyright (c) 2013年 羽田 健太郎. All rights reserved.
//

#import "IBCViewController.h"

#define UUID @"e2c56db5-dffb-48d2-b060-d0f5a71096e0"

@interface IBCViewController ()
@property(nonatomic, strong)CLLocationManager* locationManager;
@property(nonatomic, strong)CLBeaconRegion* beaconRegion;
@property(nonatomic, strong)NSUUID* proximityUUID;
@property(nonatomic, strong)AVAudioPlayer *okaeriVoice;
@property(nonatomic, strong)AVAudioPlayer *itteVoice;

@property(nonatomic)BOOL isInRegion;
@property(nonatomic)BOOL isOutRegion;
@property(nonatomic)BOOL isFirstEnterNear;
@property(nonatomic)BOOL isFirstOutNear;

@property(nonatomic, strong)NSDate* inTime;

@end

@implementation IBCViewController
@synthesize locationManager;
@synthesize beaconRegion;
@synthesize proximityUUID;
@synthesize okaeriVoice;
@synthesize itteVoice;

@synthesize isInRegion;
@synthesize isFirstEnterNear;
@synthesize isOutRegion;
@synthesize isFirstOutNear;


@synthesize inTime;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:UUID];
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                                identifier:@"jp.classmethod.testregion"];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
    
    [self settingVoice];
    
    isInRegion = false;
    isFirstEnterNear = false;
    isFirstOutNear = false;
    isOutRegion = false;
    
    messageLbl.text = @"(- ω -)\n帰宅中・・・";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - setting method

- (void)settingVoice{
    NSString *soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"oka"
                                    ofType: @"wav"];
    
    AVAudioPlayer *newPlayer =
    [[AVAudioPlayer alloc] initWithContentsOfURL: [[NSURL alloc] initFileURLWithPath: soundFilePath]
                                           error: nil];
    okaeriVoice = newPlayer;
    [okaeriVoice prepareToPlay];
    
    soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"itte"
                                    ofType: @"wav"];
     newPlayer =
    [[AVAudioPlayer alloc] initWithContentsOfURL: [[NSURL alloc] initFileURLWithPath: soundFilePath]
                                           error: nil];
    itteVoice = newPlayer;
    [itteVoice prepareToPlay];

}

#pragma mark - locationManager delegate
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.locationManager requestStateForRegion:self.beaconRegion];
}
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside: // リージョン内にいる
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
                isInRegion = true;
                regionLbl.text = @"In";
            }
            break;
        case CLRegionStateOutside:{
                isInRegion = false;
                regionLbl.text = @"Out";
            }
            break;
        case CLRegionStateUnknown:
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    // ローカル通知
    //[self sendLocalNotificationForMessage:@"Enter Region" isImmidiate:nil];
    isInRegion = true;
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // ローカル通知
    //[self sendLocalNotificationForMessage:@"Exit Region" isImmidiate:nil];
    
    if(isInRegion || [self compareWithInTime]){
        [itteVoice play];
        isInRegion = false;
    }
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
    regionLbl.text = @"Out";
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        rangeMessage = [self proxiMessage:nearestBeacon.proximity];
        
        NSString *message = [NSString stringWithFormat:@"major:%@ \n minor:%@ \n accuracy:%f \n rssi:%d \n status:%@ \n",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy,
                             (int)nearestBeacon.rssi, [self proxiMessage:nearestBeacon.proximity]];
        
        statusLbl.text = message;
        
        // 最初にNearになったとき「おかえり」
        if(((nearestBeacon.proximity == CLProximityNear) ||
           (nearestBeacon.proximity == CLProximityImmediate)) && !isFirstEnterNear){
            messageLbl.text = @"(o´･ω･`o)ﾉ\nおかえり！！";
            [okaeriVoice play];
            isFirstEnterNear = true;
            
            inTime = [NSDate dateWithTimeIntervalSinceNow:0.0f];
            kitakuTimeLbl.text = [NSString stringWithFormat:@"%@", inTime];
        }
        
        // unknownで「いてらっしゃい」
        if(isInRegion && [self compareWithInTime] &&
           ((nearestBeacon.proximity == CLProximityUnknown) && !isFirstOutNear)){
            [itteVoice play];
            isInRegion = false;
            isFirstOutNear = true;
            messageLbl.text = @"(・ω・)ノ\nいってらっしゃい！！";
        }

        // ローカル通知
        //[self sendLocalNotificationForMessage:[rangeMessage stringByAppendingString:message] isImmidiate:nearestBeacon.proximity];
    }
}


#pragma mark - additional method

// ローカルプッシュ用 - test
-(void)sendLocalNotificationForMessage:(NSString*)str isImmidiate:(CLProximity)proximatery{
    
    if(proximatery == CLProximityNear || proximatery == CLProximityImmediate || proximatery == CLProximityFar){
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    [notification setFireDate:date];
    [notification setTimeZone:[NSTimeZone localTimeZone]];
    [notification setAlertBody:[self proxiMessage:proximatery]];
    [notification setSoundName:UILocalNotificationDefaultSoundName];
    [notification setAlertAction:@"Open"];
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

-(NSString*)proxiMessage:(CLProximity)proximatery{

    NSString* rangeMessage ;
    switch (proximatery) {
        case CLProximityImmediate:
            rangeMessage = @"Range Immediate ";
            break;
        case CLProximityNear:
            rangeMessage = @"Range Near ";
            break;
        case CLProximityFar:
            rangeMessage = @"Range Far ";
            break;
        default:
            rangeMessage = @"Range Unknown ";
            break;
    }
    return rangeMessage;
}


- (BOOL)compareWithInTime{
    
    if(!inTime)return false;
    
    NSDate *now = [NSDate date];
    float tmp= [now timeIntervalSinceDate:inTime];
    int hh = (int)(tmp / 3600);
    int mm = (int)((tmp-hh) / 60);
    float ss = tmp -(float)(hh*3600+mm*60);
    if(ss > 3){
        return true;
    }
    else{
        return false;
    }
}

@end
