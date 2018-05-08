//
//  DemoDefine.h
//  TelinkBlueDemo
//
//  Created by Arvin on 2017/4/11.
//  Copyright © 2017年 Green. All rights reserved.
//

#ifndef DemoDefine_h
#define DemoDefine_h
#import "AppDelegate.h"
#import "SysSetting.h"
#import "BTDevItem.h"
#import "OTATipShowVC.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define kEndTimer(timer) \
if (timer) { \
[timer invalidate]; \
timer = nil; \
}
//OTA压包修改参数
#define kOTAPartSize (16*16)

#define kPrintPerDataSend (5)

#define kMScreenW ([UIScreen mainScreen].bounds.size.width)
#define kMScreenH ([UIScreen mainScreen].bounds.size.height)

#define kDocumentFilePath(name) ([[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:name])
#define kCanOpenBluetooth ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"prefs:root=Bluetooth"]])
#define kOpenBluetooth ([[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Bluetooth"]])
#define kCentralManager ([BTCentralManager shareBTCentralManager])
#define kSettingLastName ([SysSetting shareSetting].oUserName)
#define kSettingLastPwd ([SysSetting shareSetting].oUserPassword)
#define kSettingLatestName ([SysSetting shareSetting].nUserName)
#define kSettingLatestPwd ([SysSetting shareSetting].nUserPassword)
#endif /* DemoDefine_h */
