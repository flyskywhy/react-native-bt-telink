/********************************************************************************************************
 * @file     SysSetting.h 
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
//  SysSetting.h
//  TelinkBlueDemo
//
//  Created by Green on 11/22/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTDevItem.h"
#import <UIKit/UIKit.h>
UIKIT_EXTERN NSString *const MeshName;
UIKIT_EXTERN NSString *const MeshPassword;
UIKIT_EXTERN NSString *const DevicesInfo;
UIKIT_EXTERN NSString *const Address;
UIKIT_EXTERN NSString *const Version;
UIKIT_EXTERN NSString *const Mac;
UIKIT_EXTERN NSString *const Productuuid;

//额外保存设置界面的新旧mesh信息
#define kOldMeshInfo    @"kOldMeshInfo"
#define kCurrentMeshInfo    @"kCurrentMeshInfo"

@interface GroupInfo : NSObject

@property (nonatomic, strong) NSString *grpName;
@property (nonatomic, assign) int grpAdr;
@property (nonatomic, strong) NSMutableArray *itemArrs;

- (BOOL)isAllRoom;

+ (id)ItemWith:(NSString *)nStr Adr:(int)adr;
@end


@interface SysSetting : NSObject
@property (nonatomic, strong) NSString *currentUserName;
@property (nonatomic, strong) NSString *currentUserPassword;
@property (nonatomic, strong) NSString *oldUserName;
@property (nonatomic, strong) NSString *oldUserPassword;

@property (nonatomic, strong) NSMutableArray *grpArrs;

+ (SysSetting *)shareSetting;
- (NSArray *)currentLocalDevices;
- (NSData *)currentMeshData;

- (NSDictionary <NSString *, NSArray *>*)localData;
- (BOOL)addMesh:(BOOL)add Name:(NSString *)name pwd:(NSString *)pwd;
- (BOOL)addDevice:(BOOL)isAdd Name:(NSString *)name pwd:(NSString *)pwd device:(BTDevItem *)item address:(NSNumber *)address version:(NSString *)ver;
- (BOOL)addDevice:(BOOL)isAdd Name:(NSString *)name pwd:(NSString *)pwd devices:(NSArray <NSDictionary *>*)newdevices;

- (void)updateDeviceMessageWithName:(NSString *)name pwd:(NSString *)pwd deviceAddress:(NSNumber *)address version:(NSString *)ver type:(NSNumber *)type mac:(NSString *)mac;

///返回保存在本地的设备字典的数组，格式如上
- (NSArray <NSDictionary *>*)currentLocalDevicesDict;

///记录新旧的mesh信息
- (void)saveMeshInfoWithName:(NSString *)name password:(NSString *)password isCurrent:(BOOL)isCurrent;

///通过短地址(1、2、3)查找本地数据，找设备类型
+ (NSNumber *)getProductuuidWithDeviceAddress:(NSInteger )address;

///通过短地址(1、2、3)查找本地数据，找设备MAC
+ (NSString *)getMacWithDeviceAddress:(NSInteger )address;

@end
