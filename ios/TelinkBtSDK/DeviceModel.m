/********************************************************************************************************
 * @file     DeviceModel.m 
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
//  CentralModel.m
//  TelinkBlueDemo
//
//  Created by telink on 15/12/10.
//  Copyright © 2015年 Green. All rights reserved.
//

#import "DeviceModel.h"

@implementation DeviceModel

-(BOOL)addGrpAddressPro:(int)addAdr
{
    BOOL result=NO;
    for (int i=0; i<8; i++)
    {
        if (grpAdress[i]==0xff)
        {
            grpAdress[i]=addAdr;
            result=YES;
            break;
        }
    }
    return result;
}

-(BOOL)removeGrpAddressPro:(int)addAdr
{
    BOOL result=NO;
    for (int i=0; i<8; i++)
    {
        if (grpAdress[i]==addAdr)
        {
            grpAdress[i]=0xff;
            result=YES;
        }
    }
    return result;
}

- (void)updataLightStata:(DeviceModel *)model {
    self.stata = model.stata;
    self.brightness = model.brightness;
    self.reserve = model.reserve;
}

- (instancetype)initWithModel:(DeviceModel *)model {
    if (self=[super init]) {
        _u_DevAdress = model.u_DevAdress;
        _brightness = model.brightness;
        _stata = model.stata;
        _reserve = model.reserve;
        _versionString = model.versionString;
    }
    return self;
}

@end
