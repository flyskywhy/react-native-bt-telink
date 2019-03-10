/********************************************************************************************************
 * @file     BTDevItem.h 
 *
 * @brief    for TLSR chips
 *
 * @author	 telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *           
 *			 The information contained herein is confidential and proprietary property of Telink 
 * 		     Semiconductor (Shanghai) Co., Ltd. and is available under the terms 
 *			 of Commercial License Agreement between Telink Semiconductor (Shanghai) 
 *			 Co., Ltd. and the licensee in separate contract or the terms described here-in. 
 *           This heading MUST NOT be removed from this file.
 *
 * 			 Licensees are granted free, non-transferable use of the information in this 
 *			 file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided. 
 *           
 *******************************************************************************************************/
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
    
    uint32_t productID;//设备类型标识
    
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
