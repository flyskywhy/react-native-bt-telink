/********************************************************************************************************
 * @file     BTConst.h 
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
//  BTConst.h
//  TelinkBlue
//
//  Created by Green on 11/14/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#ifndef TelinkBlue_BTConst_h
#define TelinkBlue_BTConst_h

#define BTDevInfo_Name @"Telink tLight"
#define BTDevInfo_UserNameDef @"telink_mesh1"
#define BTDevInfo_UserPasswordDef @"123"
#define BTDevInfo_UID  0x1102

#define BTDevInfo_ServiceUUID @"00010203-0405-0607-0809-0A0B0C0D1910"
#define BTDevInfo_FeatureUUID_Notify @"00010203-0405-0607-0809-0A0B0C0D1911"
#define BTDevInfo_FeatureUUID_Command @"00010203-0405-0607-0809-0A0B0C0D1912"
#define BTDevInfo_FeatureUUID_Pair @"00010203-0405-0607-0809-0A0B0C0D1914"
#define BTDevInfo_FeatureUUID_OTA  @"00010203-0405-0607-0809-0A0B0C0D1913"

#define Service_Device_Information @"0000180a-0000-1000-8000-00805f9b34fb"

#define Characteristic_Firmware @"00002a26-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Manufacturer @"00002a29-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Model @"00002a24-0000-1000-8000-00805f9b34fb"
//#define Characteristic_Hardware @"00002a27-0000-1000-8000-00805f9b34fb"

#define CheckStr(A) (!A || A.length<1)

#define kEndTimer(timer) \
if (timer) { \
[timer invalidate]; \
timer = nil; \
}
//!<命令延时参数
//#define kDuration (500)
#endif
