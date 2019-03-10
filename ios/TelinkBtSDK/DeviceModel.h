/********************************************************************************************************
 * @file     DeviceModel.h 
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
//  CentralModel.h
//  TelinkBlueDemo
//
//  Created by telink on 15/12/10.
//  Copyright © 2015年 Green. All rights reserved.
//


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LightStataType) {
    LightStataTypeOff,
    LightStataTypeOn,
    LightStataTypeOutline
};

@interface DeviceModel : NSObject{
@public
    int grpAdress[8];
}

/**
 *地址
 */
@property(nonatomic,assign)uint32_t u_DevAdress;

/**
 *状态－0-离线状态   1-－在线关灯状态  3-－－在线开灯状态
 */

@property(nonatomic,assign)LightStataType stata;

/**
 *亮度－0-到 100；
 */
@property(nonatomic,assign)NSUInteger brightness;

@property (nonatomic, strong) NSString *versionString;

@property(nonatomic,assign)NSInteger reserve;

-(BOOL)addGrpAddressPro:(int)addAdr;
-(BOOL)removeGrpAddressPro:(int)addAdr;

- (void)updataLightStata:(DeviceModel *)model;
- (instancetype)initWithModel:(DeviceModel *)model;

@end
