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
@property(nonatomic,strong) NSMutableDictionary *dict;
@property(nonatomic, strong) NSMutableArray <BTDevItem *> *DisConnectDevArray;
@property(nonatomic,strong) NSMutableDictionary *node;
@property(nonatomic,assign) BOOL configNode;
@property(nonatomic,strong) NSString *pwd;
@property(nonatomic,assign) BOOL HomePage;
@property(nonatomic,assign) BOOL frist;
@property(nonatomic,strong) NSString *userMeshName;
@property(nonatomic,strong) NSString *userMeshPwd;
@end
