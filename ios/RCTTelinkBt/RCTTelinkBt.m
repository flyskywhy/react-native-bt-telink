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
    return @[@"serviceConnected", @"serviceDisconnected", @"notificationOnlineStatus", @"deviceStatusLogin", @"deviceStatusLogout", @"deviceStatusErrorAndroidN", @"leScan", @"leScanCompleted", @"leScanTimeout", @"meshOffline"];
}

RCT_EXPORT_METHOD(doInit) {
    [[BTCentralManager shareBTCentralManager] stopScan];
    //扫描我的在线灯
    [BTCentralManager shareBTCentralManager].delegate = self;
    self.devArray = [[NSMutableArray alloc] init];
    self.BTDevArray = [[NSMutableArray alloc] init];
    self.isNeedRescan = YES;
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
    NSLog(@"valueee=====%x ", item.u_DevAdress);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    
    [event setObject:[NSString stringWithFormat:@"%x", item.u_Mac] forKey:@"macAddress"];
    [event setObject:@"22222" forKey:@"deviceName"];
    [event setObject:[NSString stringWithFormat:@"%@", item.u_Name] forKey:@"meshName"];
    [event setObject:[NSString stringWithFormat:@"%x", item.u_DevAdress] forKey:@"meshAddress"];
    [event setObject:[NSString stringWithFormat:@"%u", item.u_meshUuid] forKey:@"meshUUID"];
    [event setObject:@"66666" forKey:@"productUUID"];
    [event setObject:[NSString stringWithFormat:@"%u", item.u_Status] forKey:@"status"];

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
    NSString *tip = [NSString stringWithFormat:@"connected device address: %x", item.u_DevAdress];
    NSLog(@"tip==========%@",tip);
}

- (void)dosomethingWhenLoginDevice:(BTDevItem *)item {

}

- (void)dosomethingWhenDisConnectedDevice:(BTDevItem *)item {

}

- (void)scanedLoginCharacteristic {
    [kCentralManager loginWithPwd:@"123"];
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
        //        [self.lightCollectionView reloadData];
        //        [self.tableView reloadData];
    }
    //delegate.devArray = self.devArray;
}

RCT_EXPORT_METHOD(doDestroy) {
    NSLog(@"11111");
}

RCT_EXPORT_METHOD(notModeAutoConnectMesh) {
    NSLog(@"11111");
}

RCT_EXPORT_METHOD(autoConnect) {
    NSLog(@"11111");
}

RCT_EXPORT_METHOD(autoRefreshNotify) {
    NSLog(@"11111");
}

RCT_EXPORT_METHOD(idleMode:(BOOL)disconnect) {
    //NSLog(@"11111");
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

RCT_EXPORT_METHOD(changePower:(NSString *)meshAddress value:(NSInteger)value) {
    for (DeviceModel *dev in self.devArray) {
        if ([[NSString stringWithFormat:@"%x", dev.u_DevAdress] isEqual:meshAddress]) {
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
    
    _resolveBlock=resolve;
    _rejectBlock=reject;

    GetLTKBuffer;
    [kCentralManager setOut_Of_MeshWithName:[cfg objectForKey:@"oldName"] PassWord:[cfg objectForKey:@"oldPwd"] NewNetWorkName:[cfg objectForKey:@"newName"] Pwd:[cfg objectForKey:@"newPwd"] ltkBuffer:ltkBuffer ForCertainItem:self.BTDevArray[index]];
}

-(void)OnDevOperaStatusChange:(id)sender Status:(OperaStatus)status{
    if (status == DevOperaStatus_SetNetwork_Finish) {
        _resolveBlock(self.devArray);
    }
}

@end
