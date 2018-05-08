//
//  BTDevItem.h
//  TelinkBlue
//
//  Created by Green on 11/14/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BTDevItem : NSObject
{
    NSString *devIdentifier;//设备标示
    NSString *name;//
    CBPeripheral *blDevInfo;//设备信息
    
    NSString *u_Name;
    uint32_t u_Vid;
    uint32_t u_Pid;
    uint32_t u_Mac;
    uint32_t u_meshUuid;
    uint32_t u_DevAdress;
    uint32_t u_Status;
    int rssi;//蓝牙信号
    
    BOOL isSeted;//是否设置了Network Info
    BOOL isSetedSuff;//设置Network Info 是否成功
    
    BOOL isConnected;//是否已连接
    BOOL isBreakOff;//是否断开 关闭或者范围之外
    
    uint32_t productID;

}
@property (nonatomic, strong) NSString *devIdentifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) CBPeripheral *blDevInfo;
@property (nonatomic, strong) NSString *u_Name;
@property (nonatomic, assign) uint32_t u_Vid;
@property (nonatomic, assign) uint32_t u_Pid;
@property (nonatomic, assign) uint32_t u_Mac;
@property (nonatomic, assign) int rssi;
@property (nonatomic, assign, getter=isConnected) BOOL isConnected;
@property (nonatomic, assign, getter=isBreakOff) BOOL isBreakOff;
@property (nonatomic, assign, getter=isSeted) BOOL isSeted;
@property (nonatomic, assign) uint32_t u_meshUuid;
@property (nonatomic, assign) uint32_t u_DevAdress;
@property (nonatomic, assign) uint32_t u_Status;
@property (nonatomic, assign, getter=isSetedSuff) BOOL isSetedSuff;

@property(nonatomic,assign)uint32_t productID;

- (instancetype)initWithDevice:(BTDevItem *)item;
- (NSString *)uuidString;
- (NSString *)description;
@end
