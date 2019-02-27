//
//  RCTTelinkBt.m
//  RCTTelinkBt
//
//  Created by 黄河 on 2018/4/23.
//  Copyright © 2018年 黄河. All rights reserved.
//

#import "RCTTelinkBt.h"
#import "RCTLog.h"
#import "BTCentralManager.h"

#define kCentralManager ([BTCentralManager shareBTCentralManager])

@interface RCTTelinkBt() <BTCentralManagerDelegate>

@end

@implementation RCTTelinkBt {
    RCTPromiseResolveBlock _resolveBlock;
    RCTPromiseRejectBlock _rejectBlock;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"bluetoothEnabled", @"bluetoothDisabled", @"serviceConnected", @"serviceDisconnected", @"notificationOnlineStatus", @"notificationGetDeviceState", @"deviceStatusConnecting", @"deviceStatusConnected", @"deviceStatusLogining", @"deviceStatusLogin",@"deviceStatusLogout",@"deviceStatusErrorAndroidN",@"deviceStatusUpdateMeshCompleted",@"deviceStatusUpdatingMesh",@"deviceStatusUpdateMeshFailure",@"deviceStatusUpdateAllMeshCompleted",@"deviceStatusGetLtkCompleted",@"deviceStatusGetLtkFailure",@"deviceStatusMeshOffline",@"deviceStatusMeshScanCompleted",@"deviceStatusMeshScanTimeout",@"deviceStatusOtaCompleted",@"deviceStatusOtaFailure",@"deviceStatusOtaProgress",@"deviceStatusGetFirmwareCompleted",@"deviceStatusGetFirmwareFailure",@"deviceStatusDeleteCompleted",@"deviceStatusDeleteFailure",@"leScan",@"leScanCompleted",@"leScanTimeout",@"meshOffline"];
}

RCT_EXPORT_METHOD(doInit) {
//    [[BTCentralManager shareBTCentralManager] stopScan];
    //扫描我的在线灯
    [BTCentralManager shareBTCentralManager].delegate = self;
    self.devArray = [[NSMutableArray alloc] init];
    self.BTDevArray = [[NSMutableArray alloc] init];
    self.isNeedRescan = YES;
    
    [self sendEventWithName:@"serviceConnected" body:nil];
    [self sendEventWithName:@"bluetoothEnabled" body:nil];
    [self sendEventWithName:@"deviceStatusLogout" body:nil];
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //第一次打开或者每次蓝牙状态改变都会调用这个函数
    if(central.state==CBCentralManagerStatePoweredOn)
    {
        NSLog(@"蓝牙设备开着");
    }
    else
    {
        NSLog(@"蓝牙设备关着");
        
        UIAlertView *alterView=[[UIAlertView alloc]initWithTitle:@"提示" message:@"请打开蓝牙！" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alterView show];
    }
    
    
}

- (void)startScan {
    kCentralManager.scanWithOut_Of_Mesh = NO;
    [kCentralManager startScanWithName:@"sysin_mesh" Pwd:@"123" AutoLogin:YES];
}

- (void)OnDevChange:(id)sender Item:(BTDevItem *)item Flag:(DevChangeFlag)flag {
    //if (!self.isStartOTA) return;
    kCentralManager.isAutoLogin = NO;
    NSLog(@"flag==========%u", flag);
    switch (flag) {
        case DevChangeFlag_Add:                 [self dosomethingWhenDiscoverDevice:item]; break;
        case DevChangeFlag_Connected:           [self dosomethingWhenConnectedDevice:item]; break;
        case DevChangeFlag_Login:               [self dosomethingWhenLoginDevice:item]; break;
        case DevChangeFlag_DisConnected:        [self dosomethingWhenDisConnectedDevice:item]; break;
        default:    break;
    }
}

#pragma mark- Delegate

- (void)dosomethingWhenDiscoverDevice:(BTDevItem *)item {
    NSLog(@"itttt==========%@", item);
    NSLog(@"valueee=====%d ", item.u_DevAdress);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    
    [event setObject:[NSString stringWithFormat:@"%x", item.u_Mac] forKey:@"macAddress"];
    [event setObject:item.name forKey:@"deviceName"];
    [event setObject:[NSString stringWithFormat:@"%@", item.u_Name] forKey:@"meshName"];
//    [event setObject:[NSString stringWithFormat:@"%x", item.u_DevAdress] forKey:@"meshAddress"];
//    [event setObject:[NSString stringWithFormat:@"%u", item.u_meshUuid] forKey:@"meshUUID"];
//    [event setObject:[NSString stringWithFormat:@"%u", item.productID] forKey:@"productUUID"];
//    [event setObject:[NSString stringWithFormat:@"%u", item.u_Status] forKey:@"status"];
    
//    [event setObject:[NSString stringWithFormat:@"%x", item.u_Mac] forKey:@"macAddress"];
//    [event setObject:item.name forKey:@"deviceName"];
//    [event setObject:[NSString stringWithFormat:@"%@", item.u_Name] forKey:@"meshName"];
    [event setObject:[NSNumber numberWithInt:item.u_DevAdress] forKey:@"meshAddress"];
    [event setObject:[NSNumber numberWithInt:item.u_meshUuid] forKey:@"meshUUID"];
    [event setObject:[NSNumber numberWithInt:item.productID] forKey:@"productUUID"];
    [event setObject:[NSNumber numberWithInt:item.u_Status] forKey:@"status"];

    
    [self sendEventWithName:@"leScan" body:event];
    
    NSMutableArray *macs = [[NSMutableArray alloc] init];
    for (int i=0; i<self.BTDevArray.count; i++) {
        [macs addObject:@(self.BTDevArray[i].u_DevAdress)];
    }
    if (![macs containsObject:@(item.u_DevAdress)]) {
        [self.BTDevArray addObject:item];
    }

    if (kCentralManager.devArrs.count==1) {
        [kCentralManager connectWithItem:item];
    }
    
    
}

- (void)dosomethingWhenConnectedDevice:(BTDevItem *)item {
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    [event setObject:[NSNumber numberWithInt:item.u_DevAdress] forKey:@"meshAddress"];
    NSString *tip = [NSString stringWithFormat:@"connected device address: %x", item.u_DevAdress];
    [self sendEventWithName:@"deviceStatusLogin" body:event];
    NSLog(@"tip==========%@",tip);
    
}

- (void)dosomethingWhenLoginDevice:(BTDevItem *)item {
    NSLog(@"dosomethingWhenLoginDevice");
}

- (void)dosomethingWhenDisConnectedDevice:(BTDevItem *)item {
    NSLog(@"dosomethingWhenDisConnectedDevice");
}

- (void)scanedLoginCharacteristic {
    [kCentralManager loginWithPwd:nil];
}

- (void)notifyBackWithDevice:(DeviceModel *)model {
    if (!model) return;
    NSMutableArray *macs = [[NSMutableArray alloc] init];
    for (int i=0; i<self.devArray.count; i++) {
        [macs addObject:@(self.devArray[i].u_DevAdress)];
    }
    //AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    //更新既有设备状态
    if ([macs containsObject:@(model.u_DevAdress)]) {
        NSUInteger index = [macs indexOfObject:@(model.u_DevAdress)];
        DeviceModel *tempModel =[self.devArray objectAtIndex:index];
        [tempModel updataLightStata:model];
        //        [self.lightCollectionView reloadData];
        //        [self.tableView reloadData];
    }
    //添加新设备
    
    else{
        DeviceModel *omodel = [[DeviceModel alloc] initWithModel:model];
        [self.devArray addObject:omodel];
        
        
    }
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    
    [event setObject:[NSNumber numberWithInt:1] forKey:@"reserve"];
    [event setObject:[NSNumber numberWithInt:1] forKey:@"status"];
    [event setObject:[NSNumber numberWithInt:2] forKey:@"brightness"];
    [event setObject:[NSNumber numberWithInt:model.u_DevAdress] forKey:@"meshAddress"];
    
    NSMutableArray *array = [NSMutableArray arrayWithObject:event];
    [self sendEventWithName:@"notificationOnlineStatus" body:array];
    
}
RCT_EXPORT_METHOD(doDestroy) {
    NSLog(@"doDestroy");
}

RCT_EXPORT_METHOD(doResume) {
    NSLog(@"doResume");
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil]; 
}

RCT_EXPORT_METHOD(enableBluetooth) {
    NSLog(@"enableBluetooth");
}

RCT_EXPORT_METHOD(notModeAutoConnectMesh:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve(@YES);
    NSLog(@"notModeAutoConnectMesh");
}


RCT_EXPORT_METHOD(autoConnect:(NSString *)userMeshName userMeshPwd:(NSString *)userMeshPwd otaMac:(NSString *)otaMac)
{
    NSLog(@"meshName==========%@",userMeshName);
    [[BTCentralManager shareBTCentralManager] stopScan];
    [self.devArray removeAllObjects];
    kCentralManager.scanWithOut_Of_Mesh = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [kCentralManager startScanWithName:userMeshName Pwd:userMeshPwd AutoLogin:YES];
    });
}

RCT_EXPORT_METHOD(autoRefreshNotify:(NSInteger) repeatCount Interval:(NSInteger) NSInteger) {
    [kCentralManager setNotifyOpenPro];
}

RCT_EXPORT_METHOD(idleMode:(BOOL)disconnect) {
    NSLog(@"idleMode");
}

RCT_EXPORT_METHOD(startScan:(NSString *)meshName outOfMeshName:(NSString *)outOfMeshName timeoutSeconds:(NSInteger)timeoutSeconds isSingleNode:(BOOL)isSingleNode) {
    NSLog(@"meshName==========%@",meshName);
    [[BTCentralManager shareBTCentralManager] stopScan];
    [self.devArray removeAllObjects];
    kCentralManager.scanWithOut_Of_Mesh = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [kCentralManager startScanWithName:meshName Pwd:@"123" AutoLogin:YES];
    });
}

RCT_EXPORT_METHOD(sendCommand:(NSInteger)opcode meshAddress:(NSInteger)meshAddress value:(NSArray *) value immediate :(BOOL)immediate) {
    NSArray *arr = [kCentralManager devArrs];
    for (BTDevItem *dev in arr) {
        if (dev.u_DevAdress == meshAddress) {
            [[BTCentralManager shareBTCentralManager] sendCommand:opcode meshAddress:dev.u_DevAdress value:value];
        }
    }
}

RCT_EXPORT_METHOD(changePower:(NSInteger)meshAddress value:(NSInteger)value) {
    NSArray *arr = [kCentralManager devArrs];
    for (BTDevItem *dev in arr) {
        if (dev.u_DevAdress == meshAddress) {
            if (value == 1) {
                [[BTCentralManager shareBTCentralManager] turnOffCertainLightWithAddress:dev.u_DevAdress];
            }
            else {
                [[BTCentralManager shareBTCentralManager] turnOnCertainLightWithAddress:dev.u_DevAdress];
            }
        }
    }
}

RCT_EXPORT_METHOD(changeBrightness:(NSString *)meshAddress value:(NSInteger)value) {
    for (DeviceModel *dev in self.devArray) {
        if ([[NSString stringWithFormat:@"%x", dev.u_DevAdress] isEqual:meshAddress]) {
            NSLog(@"brightness====%ld", dev.brightness);
            if (dev.stata==LightStataTypeOff && value>0) {
                [kCentralManager turnOnCertainLightWithAddress:dev.u_DevAdress];
            }else if (dev.stata==LightStataTypeOn && value==0) {
                [kCentralManager turnOffCertainLightWithAddress:dev.u_DevAdress];
                return;
            }
            [kCentralManager setLightOrGroupLumWithDestinateAddress:dev.u_DevAdress WithLum:value];
        }
    }
}

RCT_EXPORT_METHOD(changeTemperatur:(NSString *)meshAddress value:(float)value) {
    for (DeviceModel *dev in self.devArray) {
        if ([[NSString stringWithFormat:@"%x", dev.u_DevAdress] isEqual:meshAddress]) {
            [kCentralManager setCTOfLightWithDestinationAddress:dev.u_DevAdress AndCT:value];
        }
    }
}

RCT_EXPORT_METHOD(changeColor:(NSString *)meshAddress value:(NSInteger)value) {
    //NSLog(@"value4=====%ld", value);
    //[[BTCentralManager shareBTCentralManager] setLightOrGroupRGBWithDestinateAddress:self.selData.u_DevAdress WithColorR:red WithColorG:green WithB:blue];
}

RCT_EXPORT_METHOD(configNode:(NSDictionary *)node cfg:(NSDictionary *)cfg resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    
    NSInteger index = -1;
    
    for (int i=0; i<self.BTDevArray.count; i++) {
        if ([[NSString stringWithFormat:@"%x", self.BTDevArray[i].u_Mac] isEqualToString:[node objectForKey:@"macAddress"]]) {
            index = i;
        }
    }
    NSLog(@"index=====%ld", index);
    
    if (index < 0) {
        return;
    }
    
    self.BTDevArray[index].u_DevAdress = [node objectForKey:@"meshAddress"];

    _resolveBlock=resolve;
    _rejectBlock=reject;

    GetLTKBuffer;
    [kCentralManager setOut_Of_MeshWithName:[cfg objectForKey:@"oldName"] PassWord:[cfg objectForKey:@"oldPwd"] NewNetWorkName:[cfg objectForKey:@"newName"] Pwd:[cfg objectForKey:@"newPwd"] ltkBuffer:ltkBuffer ForCertainItem:self.BTDevArray[index]];
}

RCT_EXPORT_METHOD(setNodeGroupAddr) {
    NSLog(@"setNodeGroupAddr");
}

RCT_EXPORT_METHOD(getTime:(NSInteger)meshAddress relayTimes:(NSInteger)relayTimes resolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"getTime");
    NSArray *value = [NSArray arrayWithObject:[NSNumber numberWithInt:relayTimes]];
    NSArray *arr = [kCentralManager devArrs];
    for (BTDevItem *dev in arr) {
        if (dev.u_DevAdress == meshAddress) {
            [[BTCentralManager shareBTCentralManager] sendCommand:0xE8 meshAddress:dev.u_DevAdress value:value];
        }
    }
    resolve(@YES);
}

RCT_EXPORT_METHOD(getAlarm:(NSInteger)meshAddress relayTimes:(NSInteger)relayTimes alarmId:(NSInteger)alarmId resolver: (RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"getAlarm");
    NSArray *value = [NSArray arrayWithObjects:[NSNumber numberWithInteger:relayTimes],[NSNumber numberWithInteger:alarmId],nil];
    NSArray *arr = [kCentralManager devArrs];
    for (BTDevItem *dev in arr) {
        if (dev.u_DevAdress == meshAddress) {
            [[BTCentralManager shareBTCentralManager] sendCommand:0xE6 meshAddress:dev.u_DevAdress value:value];
        }
    }
    resolve(@YES);
}

-(void)OnDevOperaStatusChange:(id)sender Status:(OperaStatus)status{
    if (status == DevOperaStatus_SetNetwork_Finish) {
        _resolveBlock(self.devArray);
    }
}

@end
