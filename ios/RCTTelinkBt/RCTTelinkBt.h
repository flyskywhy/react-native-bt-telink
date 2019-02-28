//
//  RCTTelinkBt.h
//  RCTTelinkBt
//
//  Created by 黄河 on 2018/4/23.
//  Copyright © 2018年 黄河. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "BTDevItem.h"
#import "DeviceModel.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface RCTTelinkBt : RCTEventEmitter <RCTBridgeModule,CBCentralManagerDelegate>

@property (nonatomic, assign) BOOL isNeedRescan;
@property(nonatomic, strong) CBCentralManager *manager;
@property(nonatomic, strong) NSMutableArray <DeviceModel *> *devArray;
@property(nonatomic, strong) NSMutableArray <BTDevItem *> *BTDevArray;
@property(nonatomic,strong) NSMutableDictionary *cfg;
@property(nonatomic,strong) BTDevItem *btv;

@end
