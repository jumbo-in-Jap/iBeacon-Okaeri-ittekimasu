//
//  IBCViewController.m
//  iBeacon
//
//  Created by 羽田 健太郎 on 2013/12/01.
//  Copyright (c) 2013年 羽田 健太郎. All rights reserved.
//

#import "IBCViewController.h"

@interface IBCViewController ()
@property(nonatomic, strong)CLLocationManager* locationManager;
@property(nonatomic, strong)CLBeaconRegion* beaconRegion;
@property(nonatomic, strong)NSUUID* proximityUUID;
@property(nonatomic, strong)AVAudioPlayer *okaeriVoice;
@property(nonatomic, strong)AVAudioPlayer *itteVoice;

@property(nonatomic)BOOL isInRegion;
@property(nonatomic)BOOL isOutRegion;
@property(nonatomic)BOOL isFirstEnterNear;

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


@synthesize inTime;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        // CLLocationManagerの生成とデリゲートの設定
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        
        // 生成したUUIDからNSUUIDを作成
        //self.proximityUUID = [[NSUUID alloc] initWithUUIDString:@"80D8FFC4-9807-407C-8C4D-F7AF9248B027"];
        self.proximityUUID = [[NSUUID alloc] initWithUUIDString:@"e2c56db5-dffb-48d2-b060-d0f5a71096e0"];
        // CLBeaconRegionを作成
        self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID
                                                                identifier:@"jp.classmethod.testregion"];
        // Beaconによる領域観測を開始
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        //NSLog(@"%@", [IBCCommon getConnectionStatus]);
    }
    
    [self SettingVoice];
    
    isInRegion = false;
    isFirstEnterNear = false;
    isOutRegion = false;
    
    messageLbl.text = @"(- ω -)\n帰宅中・・・";
}

- (void)SettingVoice{
    NSString *soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"oka"
                                    ofType: @"wav"];
    
    NSURL *fileURL =
    [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
    AVAudioPlayer *newPlayer =
    [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL
                                           error: nil];
    okaeriVoice = newPlayer;
    [okaeriVoice prepareToPlay];
    
    soundFilePath =
    [[NSBundle mainBundle] pathForResource: @"itte"
                                    ofType: @"wav"];
     fileURL =
    [[NSURL alloc] initFileURLWithPath: soundFilePath];
    
     newPlayer =
    [[AVAudioPlayer alloc] initWithContentsOfURL: fileURL
                                           error: nil];
    itteVoice = newPlayer;
    [itteVoice prepareToPlay];

}

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
    
    // Beaconの距離測定を開始する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    // ローカル通知
    //[self sendLocalNotificationForMessage:@"Exit Region" isImmidiate:nil];
    
    // 出たかどうか
    if(isInRegion || [self compareWithInTime]){
        [itteVoice play];
        isInRegion = false;
    }
    
    // Beaconの距離測定を終了する
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
    regionLbl.text = @"Out";
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (beacons.count > 0) {
        // 最も距離の近いBeaconについて処理する
        CLBeacon *nearestBeacon = beacons.firstObject;
        
        NSString *rangeMessage;
        rangeMessage = [self proxiMessage:nearestBeacon.proximity];
        
        // 取得したビーコンとの情報
        NSString *message = [NSString stringWithFormat:@"major:%@ \n minor:%@ \n accuracy:%f \n rssi:%d \n status:%@ \n",
                             nearestBeacon.major, nearestBeacon.minor, nearestBeacon.accuracy,
                             (int)nearestBeacon.rssi, [self proxiMessage:nearestBeacon.proximity]];
        
        NSLog(@"%@", message);
        statusLbl.text = message;
        
        // 最初にNEar
        if(((nearestBeacon.proximity == CLProximityNear) ||
           (nearestBeacon.proximity == CLProximityImmediate)) && !isFirstEnterNear){
            messageLbl.text = @"(o´･ω･`o)ﾉ\nおかえり！！";
            [okaeriVoice play];
            isFirstEnterNear = true;
            
            inTime = [NSDate dateWithTimeIntervalSinceNow:0.0f];
            kitakuTimeLbl.text = [NSString stringWithFormat:@"%@", inTime];
        }
        
        // unknownでいてらっしゃい
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



-(void)sendLocalNotificationForMessage:(NSString*)str isImmidiate:(CLProximity)proximatery{
    
    if(proximatery == CLProximityNear || proximatery == CLProximityImmediate || proximatery == CLProximityFar){
    // ローカル通知を作成する
    UILocalNotification *notification = [[UILocalNotification alloc] init];

    // 通知日時を設定する。今から10秒後
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    [notification setFireDate:date];
    
    // タイムゾーンを指定する
    [notification setTimeZone:[NSTimeZone localTimeZone]];
    // メッセージを設定する
    [notification setAlertBody:[self proxiMessage:proximatery]];
    // 効果音は標準の効果音を利用する
    [notification setSoundName:UILocalNotificationDefaultSoundName];
    // ボタンの設定
    [notification setAlertAction:@"Open"];
    // ローカル通知を登録する
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

-(NSString*)proxiMessage:(CLProximity)proximatery{

    NSString* rangeMessage ;
    // Beacon の距離でメッセージを変える
    switch (proximatery) {
        case CLProximityImmediate:
            rangeMessage = @"Range Immediate: ";
            break;
        case CLProximityNear:
            rangeMessage = @"Range Near: ";
            break;
        case CLProximityFar:
            rangeMessage = @"Range Far: ";
            break;
        default:
            rangeMessage = @"Range Unknown: ";
            break;
    }
    return rangeMessage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)compareWithInTime{
    
    if(!inTime)return false;
    
    NSDate *now = [NSDate date];
    float tmp= [now timeIntervalSinceDate:inTime]; //差分をfloatで取得
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
