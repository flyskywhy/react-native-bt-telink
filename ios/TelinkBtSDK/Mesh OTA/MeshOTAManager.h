/********************************************************************************************************
 * @file     MeshOTAManager.h
 *
 * @brief    for TLSR chips
 *
 * @author     telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *
 *             The information contained herein is confidential and proprietary property of Telink
 *              Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 *             of Commercial License Agreement between Telink Semiconductor (Shanghai)
 *             Co., Ltd. and the licensee in separate contract or the terms described here-in.
 *           This heading MUST NOT be removed from this file.
 *
 *              Licensees are granted free, non-transferable use of the information in this
 *             file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided.
 *
 *******************************************************************************************************/
//
//  MeshOTAManager.h
//  TelinkBlueDemo
//
//  Created by Arvin on 2018/4/24.
//  Copyright © 2018年 Green. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTCentralManager.h"

typedef void(^ProgressBlock)(MeshOTAState meshState,NSInteger progress);
typedef void(^FinishBlock)(NSInteger successNumber,NSInteger failNumber);
typedef void(^ErrorBlock)(NSError *error);

@interface MeshOTAManager : NSObject

+ (MeshOTAManager*)share;

///开始meshOTA，设备在非OTA状态下时调用
- (void)startMeshOTAWithDeviceType:(NSInteger )deviceType otaData:(NSData *)otaData progressHandle:(ProgressBlock )progressBlock finishHandle:(FinishBlock )finishBlock errorHandle:(ErrorBlock )errorBlock;

///继续meshOTA，打开APP发现本地存在meshOTA的state数据时调用
- (void)continueMeshOTAWithDeviceType:(NSInteger )deviceType progressHandle:(ProgressBlock )progressBlock finishHandle:(FinishBlock )finishBlock errorHandle:(ErrorBlock )errorBlock;

///调整meshOTA，上面的start和continue两个接口会自动调用stop，用户中途想停止meshOTA可以调用该接口
- (void)stopMeshOTA;

///查询当前是否处在meshOTA
- (BOOL)isMeshOTAing;

///设置是否处理mac地址的notify回包(bytes[7] == 0xe1),因为meshAdd时，会收到大量不需要处理的mac回包。
- (void)setHandleMacNotify:(BOOL)able;

///设置当前的设备状态列表
- (void)setCurrentDevices:(NSArray <DeviceModel *>*)devices;

- (NSArray <DeviceModel *>*)getAllDevices;

- (BOOL)hasMeshStateData;

- (NSDictionary *)getSaveMeshStateData;

@end
