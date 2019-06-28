/********************************************************************************************************
 * @file     SysSetting.m 
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
//  SysSetting.m
//  TelinkBlueDemo
//
//  Created by Green on 11/22/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import "SysSetting.h"
#import "zipAndUnzip+zipString.h"
#import "zipAndUnzip.h"
NSString *const MeshName = @"n";
NSString *const MeshPassword = @"p";
NSString *const DevicesInfo = @"d";
NSString *const Address = @"a";
NSString *const Version = @"v";
NSString *const Mac = @"m";
NSString *const Productuuid = @"pu";
@implementation GroupInfo


-(id)init {
    if (self = [super init]) {
        _itemArrs=[[NSMutableArray alloc] init];
    }
    return self;
}

+(id)ItemWith:(NSString *)nStr Adr:(int)adr {
    GroupInfo *tempItem=[[GroupInfo alloc] init];
    tempItem.grpName=nStr;
    tempItem.grpAdr=adr;
    return tempItem;
}

-(BOOL)isAllRoom {
    return self.grpAdr==0xe000;
}


@end

static SysSetting *shareSysSetting = nil;
@implementation SysSetting
- (void)initData {
    _grpArrs=[[NSMutableArray alloc] init];
    [_grpArrs addObject:[GroupInfo ItemWith:@"All Devices" Adr:0xffff]];
    [_grpArrs addObject:[GroupInfo ItemWith:@"Living Room" Adr:0x8001]];
    [_grpArrs addObject:[GroupInfo ItemWith:@"Family Room" Adr:0x8002]];
    [_grpArrs addObject:[GroupInfo ItemWith:@"Kitchen" Adr:0x8003]];
    [_grpArrs addObject:[GroupInfo ItemWith:@"Bedroom" Adr:0x8004]];
    NSDictionary *dic = [self localData];
    if (dic.allKeys.count<1) {
        _currentUserName = @"telink_mesh1";
        _currentUserPassword = @"123";
        [self saveMeshInfoWithName:_currentUserName password:_currentUserPassword isCurrent:YES];
        [self saveMeshInfoWithName:@"" password:@"" isCurrent:NO];
    }
}

+ (SysSetting *)shareSetting {
    static dispatch_once_t disOnce;
    dispatch_once(&disOnce, ^{
        shareSysSetting = [[SysSetting alloc] init];
        [shareSysSetting initData];
    });
    return shareSysSetting;
}

- (NSString *)LocalDataPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"achivLocalData"];
}
- (BOOL)saveData:(NSDictionary<NSString *, NSArray *> *)tempdata {
    NSDictionary *dic = [[NSDictionary alloc] initWithDictionary:tempdata];
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    BOOL ret = [data writeToFile:[self LocalDataPath] atomically:YES];
    if (ret) {
        NSLog(@"save success");
    }else{
        NSLog(@"save fail");
    }
    return ret;
}
- (void)alasisData:(NSString *)data {
    NSDictionary *dic = [data propertyListFromStringsFileFormat];
    [self addDevice:true Name:dic[@"n"] pwd:dic[@"p"] devices:dic[@"d"]];
}
- (NSArray *)currentLocalDevices {
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",self.currentUserName,self.currentUserPassword];
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    if ([mutDic.allKeys containsObject:meshkey]) {
        NSArray *arr = [NSArray arrayWithArray:mutDic[meshkey]];
        NSMutableArray *devices = [[NSMutableArray alloc] init];
        for (NSDictionary *dic in arr) {
            [devices addObject:dic[Address]];
        }
        return devices;
    }else{
        return nil;
    }
}

/*
 (
 {a = 1;m = "bc:6b:0c:22";pu = 4;v = "";},
 {a = 2;m = "bc:6b:0c:22";pu = 4;v = "";},
 {a = 3;m = "bc:6b:0c:22";pu = 4;v = "";},
 {a = 4;m = "65:50:b9:37";pu = 4;v = "";},
 {a = 5;m = "bc:6b:0c:22";pu = 4; v = "";}
 )
 */
///返回保存在本地的设备字典的数组，格式如上
- (NSArray <NSDictionary *>*)currentLocalDevicesDict{
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",self.currentUserName,self.currentUserPassword];
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    if ([mutDic.allKeys containsObject:meshkey]) {
        NSArray *arr = [NSArray arrayWithArray:mutDic[meshkey]];
        return arr;
    }else{
        return nil;
    }
}

- (NSData *)currentMeshData {
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",self.currentUserName,self.currentUserPassword];
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    if ([mutDic.allKeys containsObject:meshkey]) {
        NSMutableDictionary *qrdic = [[NSMutableDictionary alloc] init];
        qrdic[MeshName] = self.currentUserName;
        qrdic[MeshPassword] = self.currentUserPassword;
        qrdic[DevicesInfo] = mutDic[meshkey];
        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:qrdic options:NSJSONWritingPrettyPrinted error:&error];
        NSData *createData = [zipAndUnzip gzipDeflate:json];
        NSString *content = [NSString stringWithFormat:@"%@", createData];
        content = [content substringWithRange:NSMakeRange(1, content.length - 2)];
        NSString *resultContent = [content stringByReplacingOccurrencesOfString:@" " withString:@"" options:0 range:NSMakeRange(0, content.length)];
        NSData *resultData = [resultContent dataUsingEncoding:NSUTF8StringEncoding];

        return resultData;
    }else{
        return nil;
    }
    
}
- (BOOL)addMesh:(BOOL)add Name:(NSString *)name pwd:(NSString *)pwd {
    NSAssert(name.length>0, @"mesh name is cann't be nil");
    NSAssert(pwd.length>0, @"mesh password is cann't be nil");
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",name,pwd];
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    if ([mutDic.allKeys containsObject:meshkey]) {
        if (add) {
            return YES;
        }else{
            [mutDic removeObjectForKey:meshkey];
        }
    }else{
        if (add) {
            mutDic[meshkey] = @[];
        }else{
            return YES;
        }
    }
    return [self saveData:mutDic];
}

- (BOOL)addDevice:(BOOL)isAdd Name:(NSString *)name pwd:(NSString *)pwd device:(BTDevItem *)item address:(NSNumber *)address version:(NSString *)ver{
    NSString *macAddress = [NSString stringWithFormat:@"%x",item.u_Mac];
    NSMutableString *macString = [[NSMutableString alloc] init];
    if (macAddress.length<8) {
        [macString appendString:@"0"];
    }else{
        for (int i = 3; i>=0; i--) {
            [macString appendString:[macAddress substringWithRange:NSMakeRange(i*2, 2)]];
            if (i) {
                [macString appendString:@":"];
            }
        }
    }
    if (address.intValue>255) {
        address = @((address.intValue>>8)&0xff);
    }
    if (!ver) {
        ver = @"";
    }
    NSNumber *uid = @(0);
    if (item) {
        uid = @(item.productID);
    }
    NSDictionary *dic = @{
                          Address : address,
                          Mac : macString,
                          Productuuid : uid,
                          Version : ver
                          };
    NSLog(@"%s->%@",__func__,dic);
    return [self addDevice:isAdd Name:name pwd:pwd devices:@[dic]];
}

- (BOOL)addDevice:(BOOL)isAdd Name:(NSString *)name pwd:(NSString *)pwd devices:(NSArray <NSDictionary *>*)newdevices {
    NSAssert(name.length>0, @"mesh name is cann't be nil");
    NSAssert(pwd.length>0, @"mesh password is cann't be nil");
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",name,pwd];
    
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    NSMutableArray *devices = [[NSMutableArray alloc] initWithArray:mutDic[meshkey]];
    for (NSDictionary *newDic in newdevices) {
        if (isAdd) {
            if ([mutDic.allKeys containsObject:meshkey]) {
                NSMutableArray *addreses = [NSMutableArray new];
                for (NSDictionary *dic in devices) {
                    [addreses addObject:dic[Address]];
                }
                if ([addreses containsObject:newDic[Address]]) {
                    NSUInteger index = [addreses indexOfObject:newDic[Address]];
                    //更新
                    [devices replaceObjectAtIndex:index withObject:newDic];
                }else{
                    [devices addObject:newDic];
                }
            }else{
                //添加
                [devices addObject:newDic];
            }
        }else{
            if ([mutDic.allKeys containsObject:meshkey]) {
                NSMutableArray *addreses = [NSMutableArray new];
                for (NSDictionary *dic in mutDic[meshkey]) {
                    [addreses addObject:dic[Address]];
                }
                if ([addreses containsObject:newDic[Address]]) {
                    NSUInteger index = [addreses indexOfObject:newDic[Address]];
                    //移除
                    [devices removeObjectAtIndex:index];
                }
            }
        }
    }
    mutDic[meshkey] = devices;
    return [self saveData:mutDic];
}

- (void)updateDeviceMessageWithName:(NSString *)name pwd:(NSString *)pwd deviceAddress:(NSNumber *)address version:(NSString *)ver type:(NSNumber *)type mac:(NSString *)mac{
    NSAssert(name.length>0, @"mesh name is cann't be nil");
    NSAssert(pwd.length>0, @"mesh password is cann't be nil");
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",name,pwd];
    
    NSMutableDictionary *mutDic = [[NSMutableDictionary alloc] initWithDictionary:[self localData]];
    NSMutableArray *devices = [[NSMutableArray alloc] initWithArray:mutDic[meshkey]];
    
    NSMutableArray *addreses = [NSMutableArray new];
    for (NSDictionary *dic in devices) {
        [addreses addObject:dic[Address]];
    }
    if ([addreses containsObject:address]) {
        NSUInteger index = [addreses indexOfObject:address];
        NSDictionary *oldDict = devices[index];
        //更新
        NSMutableDictionary *newDic = [[NSMutableDictionary alloc] initWithDictionary:oldDict];
        newDic[Address] = address;
        if(mac && mac.length) newDic[Mac] = mac;
        if(ver && ver.length) newDic[Version] = ver;
        if(type && type.integerValue != 0) newDic[Productuuid] = type;
        [devices replaceObjectAtIndex:index withObject:newDic];
    }else{
        NSMutableDictionary *newDic = [[NSMutableDictionary alloc] initWithDictionary:@{Address : @"",Mac : @"",Productuuid : @(0),Version : @""}];
        newDic[Address] = address;
        if(mac && mac.length) newDic[Mac] = mac;
        if(ver && ver.length) newDic[Version] = ver;
        if(type && type.integerValue != 0) newDic[Productuuid] = type;
        [devices addObject:newDic];
    }
    mutDic[meshkey] = devices;
    [self saveData:mutDic];
}

- (NSDictionary <NSString *, NSArray *>*)localData {
    NSData *localData = [NSData dataWithContentsOfFile:[self LocalDataPath]];
    NSError *error = nil;
    NSDictionary<NSString *, NSArray *> *temp = nil;
    if (localData) {
        temp = [NSJSONSerialization JSONObjectWithData:localData options:NSJSONReadingMutableLeaves error:&error];
        if (!temp) {
            temp = [[NSDictionary<NSString *, NSArray *> alloc] init];
            [self saveData:temp];
        }
    }else{
        temp = [[NSDictionary<NSString *, NSArray *> alloc] init];
        [self saveData:temp];
    }
    return temp;
}

#pragma mark - 新增，单独存储新旧mesh信息
///记录新旧的mesh信息
- (void)saveMeshInfoWithName:(NSString *)name password:(NSString *)password isCurrent:(BOOL)isCurrent{
    if(!name) name = @"";
    if(!password) password = @"";
    NSString *meshkey = [NSString stringWithFormat:@"%@+%@",name,password];
    if (isCurrent) {
        [[NSUserDefaults standardUserDefaults] setObject:meshkey forKey:kCurrentMeshInfo];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:meshkey forKey:kOldMeshInfo];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)getMeshInfoWithIsCurrent:(BOOL)isCurrent{
    NSString *meshkey = @"";
    if (isCurrent) {
        meshkey = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentMeshInfo];
    } else {
        meshkey = [[NSUserDefaults standardUserDefaults] objectForKey:kOldMeshInfo];
    }
    NSArray *tem = [meshkey componentsSeparatedByString:@"+"];
    return tem;
}

- (NSString *)currentUserName{
    NSArray *meshInfo = [self getMeshInfoWithIsCurrent:YES];
    if(meshInfo && meshInfo.count > 0){
        _currentUserName = meshInfo.firstObject;
    }else{
        _currentUserName = @"";
    }
    return _currentUserName;
}

- (NSString *)currentUserPassword{
    NSArray *meshInfo = [self getMeshInfoWithIsCurrent:YES];
    if(meshInfo && meshInfo.count > 1){
        _currentUserPassword = meshInfo.lastObject;
    }else{
        _currentUserPassword = @"";
    }
    return _currentUserPassword;
}

- (NSString *)oldUserName{
    NSArray *meshInfo = [self getMeshInfoWithIsCurrent:NO];
    if(meshInfo && meshInfo.count > 0){
        _oldUserName = meshInfo.firstObject;
    }else{
        _oldUserName = @"";
    }
    return _oldUserName;
}

- (NSString *)oldUserPassword{
    NSArray *meshInfo = [self getMeshInfoWithIsCurrent:NO];
    if(meshInfo && meshInfo.count > 1){
        _oldUserPassword = meshInfo.lastObject;
    }else{
        _oldUserPassword = @"";
    }
    return _oldUserPassword;
}

///通过短地址(1、2、3)查找本地数据，找设备类型
+ (NSNumber *)getProductuuidWithDeviceAddress:(NSInteger )address{
    NSArray *dataArray = [[SysSetting shareSetting] currentLocalDevicesDict];
    for (NSDictionary *dict in dataArray) {
        NSNumber *temAdd = (NSNumber *)dict[Address];
        if ([temAdd isEqualToNumber:@(address)]) {
            return (NSNumber *)dict[Productuuid];
        }
    }
    return @(0);
}

///通过短地址(1、2、3)查找本地数据，找设备MAC
+ (NSString *)getMacWithDeviceAddress:(NSInteger )address{
    NSArray *dataArray = [[SysSetting shareSetting] currentLocalDevicesDict];
    for (NSDictionary *dict in dataArray) {
        NSNumber *temAdd = (NSNumber *)dict[Address];
        if ([temAdd isEqualToNumber:@(address)]) {
            return (NSString *)dict[Mac];
        }
    }
    return @"";
}

@end
