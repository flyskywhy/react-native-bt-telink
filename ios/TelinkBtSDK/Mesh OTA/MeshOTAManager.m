/********************************************************************************************************
 * @file     MeshOTAManager.m
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
//  MeshOTAManager.m
//  TelinkBlueDemo
//
//  Created by Arvin on 2018/4/24.
//  Copyright © 2018年 Green. All rights reserved.
//

#import "MeshOTAManager.h"
#import "UIAlertView+Extension.h"
#import "DemoDefine.h"
#import "BTCentralManager.h"

//发送多长的OTA数据查询一次直连灯Fairware
#define kMeshOTAPicketSize  (16 * 8)
//每个OTA数据包之间的时间间隔
#define kSendOTAInterval  0.01
//APP尝试连接mesh时间间隔(设备异常断开、设备reboot断开需要用到)
#define kConnectInterval  5
//设备reboot后重启，获取所有Fairware的时间间隔(防止设备过多时丢包)
#define kReadFairwareInterval  3

@interface MeshOTAManager(){
    BTCentralManager *centraManager;
}
@property(nonatomic, strong) NSTimer *otaTimer;
@property(nonatomic, strong) NSTimer *readFirmwareTimer;
@property(nonatomic, strong) NSTimer *connectTimer;

@property(nonatomic, assign) NSInteger deviceType;
@property(nonatomic, strong) NSData *otaData;
@property (nonatomic, copy) ProgressBlock progressBlock;
@property (nonatomic, copy) FinishBlock finishBlock;
@property (nonatomic, copy) ErrorBlock errorBlock;

@property (nonatomic, assign) NSInteger number;//数据包的包个数；
@property (nonatomic, assign) NSInteger location;//当前所发送的包的Index
@property (nonatomic, assign) BOOL userClickOTA;//标记用户是否已经开始OTA
@property (nonatomic, assign) BOOL isHandleNotify;//标记是否处理通知
@property (nonatomic, assign) BOOL singleOTAStart;//标记meshOTA第一阶段压包是否已经开始
@property (nonatomic, assign) BOOL singleOTAFinish;//标记meshOTA第一阶段压包是否完成
@property (nonatomic, assign) BOOL notifyOTAFinish;//标记meshOTA第二阶段广播是否完成
@property (nonatomic, assign) BOOL waitFirmware;//标记是否在等待节点版本号notify

@property (nonatomic, strong) NSMutableArray <DeviceModel *>*devices;//当前设备在线状态的列表
@property (nonatomic, strong) NSMutableArray <DeviceModel *>*oldDevices;//OTA前设备列表
@property (nonatomic, strong) NSMutableArray *notifyAddress;//记录OTA后回复版本号的设备地址@(0)

@property (nonatomic, strong) BTDevItem *otaDevice;//标记进行meshOTA的直连灯
@property (nonatomic, assign) MeshOTAState meshState;//标记mesh状态
@property (nonatomic, assign) BOOL canHanbleMacNotify;//标记是否处理mac地址回包0xe1

@end

@implementation MeshOTAManager

+ (MeshOTAManager*)share{
    static MeshOTAManager *meshOTAManager = nil;
    static dispatch_once_t tempOnce=0;
    dispatch_once(&tempOnce, ^{
        meshOTAManager = [[MeshOTAManager alloc] init];
        [meshOTAManager initData];
    });
    return meshOTAManager;
}

-(void)initData {
    centraManager = [BTCentralManager shareBTCentralManager];
    self.isHandleNotify = NO;
    self.singleOTAStart = NO;
    self.singleOTAFinish = NO;
    self.notifyOTAFinish = NO;
    
    self.meshState = MeshOTAState_no;
    self.notifyAddress = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OnConnectionDevFirmWareNotification:) name:kOnConnectionDevFirmWareNotify object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OnDevChangeNotification:) name:kOnDevChangeNotify object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OnDevNotifyNotification:) name:kOnDevNotifyNotify object:nil];
}

- (void)startMeshOTAWithDeviceType:(NSInteger )deviceType otaData:(NSData *)otaData progressHandle:(ProgressBlock )progressBlock finishHandle:(FinishBlock )finishBlock errorHandle:(ErrorBlock )errorBlock{
    if (!self.devices && self.devices.count == 0) {
        [UIAlertView alertWithMessage:@"请先设置设备状态列表到meshOTA管理类(setCurrentDevices)"];
        return;
    }
    
    self.deviceType = deviceType;
    self.otaData = otaData;
    self.progressBlock = progressBlock;
    self.finishBlock = finishBlock;
    self.errorBlock = errorBlock;
    self.isHandleNotify = YES;
    
    self.userClickOTA = YES;
    self.singleOTAFinish = NO;
    self.otaDevice = centraManager.selConnectedItem;
    centraManager.isAutoLogin = NO;
    
    //1.查询
    [[BTCentralManager shareBTCentralManager] readMeshOTAState];
//    ARShowTips.shareTips.showTip(@"start check meshOTA state");
}

- (void)continueMeshOTAWithDeviceType:(NSInteger )deviceType progressHandle:(ProgressBlock )progressBlock finishHandle:(FinishBlock )finishBlock errorHandle:(ErrorBlock )errorBlock{
    self.deviceType = deviceType;
    self.progressBlock = progressBlock;
    self.finishBlock = finishBlock;
    self.errorBlock = errorBlock;
    self.isHandleNotify = YES;
    self.otaDevice = centraManager.selConnectedItem;
    centraManager.isAutoLogin = NO;
    
    //1.查询
//    [[BTCentralManager shareBTCentralManager] readMeshOTAState];
    //为了与notifyOpen、setTime错开发包时间，增加延时1s
    [[BTCentralManager shareBTCentralManager] performSelector:@selector(readMeshOTAState) withObject:nil afterDelay:1.0];
//    ARShowTips.shareTips.showTip(@"start check meshOTA state");
}

- (void)stopMeshOTA{
    self.deviceType = 0;
    self.otaData = nil;
    self.progressBlock = nil;
    self.finishBlock = nil;
    self.errorBlock = nil;
    self.isHandleNotify = NO;
    
    kEndTimer(self.otaTimer)
    kEndTimer(self.connectTimer)
    self.location = 0;
    self.singleOTAStart = NO;
    self.singleOTAFinish = NO;
    self.waitFirmware = NO;
    self.notifyOTAFinish = NO;
    [self.notifyAddress removeAllObjects];
    
    [self.oldDevices removeAllObjects];
    for (DeviceModel *model in self.devices) {
        [self.oldDevices addObject:[[DeviceModel alloc] initWithModel:model]];
    }
    if (self.meshState == MeshOTAState_continue) {
        [centraManager meshOTAStop];
    }
    self.meshState = MeshOTAState_no;
    [self clearMeshState];
//    ARShowTips.shareTips.delayHidden(1);
    
}

- (void)setCurrentDevices:(NSArray <DeviceModel *>*)devices{
    if (self.devices == nil) {
        self.devices = [NSMutableArray array];
        self.oldDevices = [NSMutableArray array];
    }
    //更新或者新增
    for (DeviceModel *newDevice in devices) {
        BOOL isNew = YES;
        for (DeviceModel *oldDevice in self.devices) {
            if (newDevice.u_DevAdress == oldDevice.u_DevAdress) {
                [oldDevice updataLightStata:newDevice];
                isNew = NO;
                //更新oldDevices的在线状态
                for (DeviceModel *model in self.oldDevices) {
                    if (newDevice.u_DevAdress == model.u_DevAdress) {
                        [model updataLightStata:newDevice];
                        break;
                    }
                }
                break;
            }
        }
        if (isNew) {
            [self.devices addObject:newDevice];
            [self.oldDevices addObject:[[DeviceModel alloc] initWithModel:newDevice]];
        }
    }
    //删除
    NSMutableArray *delArray = [NSMutableArray array];
    for (DeviceModel *oldDevice in self.devices) {
        BOOL hasDel = YES;
        for (DeviceModel *newDevice in devices) {
            if (newDevice.u_DevAdress == oldDevice.u_DevAdress) {
                hasDel = NO;
                break;
            }
        }
        if (hasDel) {
            [delArray addObject:oldDevice];
        }
    }
    [self.devices removeObjectsInArray:delArray];
    [self.oldDevices removeObjectsInArray:delArray];
}

- (NSArray<DeviceModel *> *)getAllDevices{
    return self.devices;
}

- (DeviceModel *)getDeviceModelWithAddress:(NSInteger)address{
    DeviceModel *tem = nil;
    for (DeviceModel *device in self.devices) {
        if (device.u_DevAdress >> 8 == address) {
            tem = device;
            break;
        }
    }
    return tem;
}

#pragma mark - Notification
- (void)OnConnectionDevFirmWareNotification:(NSNotification *)notify{
    if (self.isHandleNotify) {
        NSDictionary *dict = notify.userInfo;
        NSData *data = dict[@"data"];
        BTDevItem *item = dict[@"item"];
        [self OnConnectionDevFirmWare:data Item:item];
    }
}

- (void)OnDevChangeNotification:(NSNotification *)notify{
    if (self.isHandleNotify) {
        NSDictionary *dict = notify.userInfo;
        id sender = dict[@"sender"];
        BTDevItem *item = dict[@"item"];
        DevChangeFlag flag = 0;
        if(dict[@"flag"]){
            flag = (DevChangeFlag)[dict[@"flag"] integerValue];
        }
        [self OnDevChange:sender Item:item Flag:flag];
    }
}

- (void)OnDevNotifyNotification:(NSNotification *)notify{
    //    if (self.isHandleNotify) {
    NSDictionary *dict = notify.userInfo;
    id sender = dict[@"sender"];
    NSData *data = dict[@"data"];
    uint8_t *bytes = (uint8_t *)data.bytes;
    [self OnDevNotify:sender Byte:bytes];
    //    }
}

#pragma mark - BTCentralManager(通过通知返回，无需设置代理)
-(void)OnConnectionDevFirmWare:(NSData *)data Item:(BTDevItem *)item{
    if (self.waitFirmware) {
        self.waitFirmware = NO;
        [self sendOTAPacket];
        return;
    }
}

-(void)OnDevChange:(id)sender Item:(BTDevItem *)item Flag:(DevChangeFlag)flag{
    NSLog(@"%@",item);
    if (flag == DevChangeFlag_Add) {
        NSLog(@"添加了设备");
    }
    if (item && flag == DevChangeFlag_Connected) {
        
    }else if(item && flag == DevChangeFlag_Login){
        centraManager.isAutoLogin = NO;
        kEndTimer(self.connectTimer)
//        [centraManager readMeshOTAState];
        //为了与notifyOpen、setTime错开发包时间，增加延时1s
        [[BTCentralManager shareBTCentralManager] performSelector:@selector(readMeshOTAState) withObject:nil afterDelay:1.0];
    }else if(item && (flag == DevChangeFlag_DisConnected || flag == DevChangeFlag_ConnecteFail)){
        NSLog(@"centraManager.isAutoLogin = %d",centraManager.isAutoLogin);
        //判断是否OTA失败
        if (flag == DevChangeFlag_DisConnected && !self.singleOTAFinish && self.location < self.number && self.location != 0) {
            NSError *error = [NSError errorWithDomain:@"OTA fail" code:DevChangeFlag_DisConnected userInfo:nil];
            if (self.errorBlock) {
                self.errorBlock(error);
            }
            [self stopMeshOTA];
        }
        
        //判断是否需要重连原来的设备
        kEndTimer(self.connectTimer)
        if (self.singleOTAFinish || self.notifyOTAFinish) {
            self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:kConnectInterval target:self selector:@selector(startConnectCurrentOTADevice) userInfo:nil repeats:YES];
        }else{
            self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:kConnectInterval target:self selector:@selector(startConnectMesh) userInfo:nil repeats:YES];
        }
        
    }
}

- (void)OnDevNotify:(id)sender Byte:(uint8_t *)bytes {
    if (bytes[7]==0xc8) {
        //返回版本信息
        uint32_t address = bytes[3];
        if (bytes[10]==0) {
            //get version back
            
            NSData *data = [NSData dataWithBytes:bytes length:20];
            NSString *firm = [[NSString alloc]initWithData:[data subdataWithRange:NSMakeRange(11, 4)] encoding:NSUTF8StringEncoding];
            
            if (self.notifyOTAFinish) {
                //OTA结束后获取版本号进行比较
                NSString *tip = [NSString stringWithFormat:@"OTA结束后获取版本号进行比较 address=%d firm=%@",address,firm];
                NSLog(@"%@",tip);
                [[BTCentralManager shareBTCentralManager] performSelector:@selector(printContentWithString:) withObject:tip];
                NSInteger type = [SysSetting getProductuuidWithDeviceAddress:address].integerValue;
                NSInteger selectType = self.deviceType;
                
                if (![self.notifyAddress containsObject:@(address)] && type == selectType) {
                    [self.notifyAddress addObject:@(address)];
                }
                [self saveVersionString:firm toDeviceAddress:address isOldArray:NO];
                if ([self getOnlineDeviceNumberOfDeviceType:self.deviceType] == self.notifyAddress.count) {
                    kEndTimer(self.readFirmwareTimer)
                    //所有设备版本号获取完毕
                    [self showMeshOTAResult];
                }
            }else if (!self.singleOTAStart && !self.singleOTAFinish){
                //未OTA前查询版本号
                NSString *tip = [NSString stringWithFormat:@"未OTA前查询版本号 address=%d firm=%@",address,firm];
                NSLog(@"%@",tip);
                [[BTCentralManager shareBTCentralManager] performSelector:@selector(printContentWithString:) withObject:tip];
                [self saveVersionString:firm toDeviceAddress:address isOldArray:YES];
            }
        }
        //返回版本校验信息
        else if (bytes[10]==3) {
            if (bytes[11]==1) {
                //verify version failure
                
            }
        }
        //返回进度信息
        else if (bytes[10] == 4) {
            int progress = bytes[11];
            if (progress <= 99 && progress > 0) {
                self.meshState = MeshOTAState_continue;
                self.otaDevice = centraManager.selConnectedItem;
                
                if (progress == 99) {
                    self.notifyOTAFinish = YES;
//                    ARShowTips.shareTips.showTip(@"Rebooting");
                }else if (progress < 99) {
                    //保存mesh状态到本地
                    [self saveMeshState];
                    if (self.progressBlock) {
                        self.progressBlock(MeshOTAState_continue, progress);
                    }
//                    NSString *t = [NSString stringWithFormat:@"正在广播ota包: %d%%", progress];
//                    ARShowTips.shareTips.showTip(t);
                }
            }
        }
        //返回主节点 mesh ota 运行状态
        else if (bytes[10]==5) {
            if (bytes[11] != 0) {
                self.meshState = bytes[11];
            }
            
            if  (bytes[11] == 0 || bytes[11] == 2){
                if (bytes[11] == 0) {
                    if (self.userClickOTA) {
                        NSString *tip = [NSString stringWithFormat:@"start meshOTA,type:%ld",(long)self.deviceType];
//                        ARShowTips.shareTips.showTip(tip);
                        //2.进入mesh OTA状态
                        [[BTCentralManager shareBTCentralManager] changeMeshStateToMeshOTAWithDeviceType:self.deviceType];
                    }else if (!self.notifyOTAFinish){
                        //在广播OTA包阶段
                        if ([self hasMeshStateData]) {
                            NSString *tipString = [NSString stringWithFormat:@"非用户操作，出现MeshOTA状态：%d，mesh Stop",bytes[11]];
                            NSError *error = [NSError errorWithDomain:tipString code:DevChangeFlag_DisConnected userInfo:nil];
                            if (self.errorBlock) {
                                self.errorBlock(error);
                            }
                            [centraManager meshOTAStop];
                            [self stopMeshOTA];
                        }
                    }
                }else if (bytes[11] == 2){
                    if (self.notifyOTAFinish) {
//                        ARShowTips.shareTips.showTip(@"Rebooting");
                    } else {
//                        ARShowTips.shareTips.showTip(@"package meshing...");
                    }
                }
            }else if  (bytes[11] == 4){
                //2.mesh OTA正常结束，获取节点版本号，判断成功失败个数
                kEndTimer(self.readFirmwareTimer)
                self.singleOTAStart = YES;
                self.singleOTAFinish = YES;
                self.notifyOTAFinish = YES;
                self.waitFirmware = YES;
                self.readFirmwareTimer = [NSTimer scheduledTimerWithTimeInterval:kReadFairwareInterval target:centraManager selector:@selector(readFirmwareVersion) userInfo:nil repeats:YES];
//                ARShowTips.shareTips.showTip(@"Reboot successful,getting firmware");
            }else{
                NSString *tipString = [NSString stringWithFormat:@"出现异常MeshOTA状态：%d，mesh Stop",bytes[11]];
                NSError *error = [NSError errorWithDomain:tipString code:DevChangeFlag_DisConnected userInfo:nil];
                if (self.errorBlock) {
                    self.errorBlock(error);
                }
                
                [centraManager meshOTAStop];
                [self stopMeshOTA];
            }
        }else if (bytes[10] == 6) {
            if (bytes[11] == 0 && self.userClickOTA) {
                self.userClickOTA = NO;
                
                self.meshState = MeshOTAState_normal;
                //3.进入mesh OTA状态成功，发送OTA数据包
                self.location = 0;
                [centraManager resetOTAPackIndex];
                //为提高手机的兼容性，在点对点OTA阶段，APPlogin成功后，ios与安卓统一延时三秒钟，再发送OTA数据包。
                [self performSelector:@selector(sendOTAPacket) withObject:nil afterDelay:3];
            }
        }
    }else if (bytes[7] == 0xe1 && bytes[16] == 0xff && bytes[17]==0xff) {
        //获取mac和设备类型回包
        if (self.canHanbleMacNotify) {
            NSMutableString *macAddress = [[NSMutableString alloc] init];
            for (int i=5; i>=0; i--) {
                Byte mac = 0;
                memcpy(&mac, bytes+12+i, 1);
                [macAddress appendString:[NSString stringWithFormat:@"%02X", mac]];
                if (i) [macAddress appendString:@":"];
            }
            uint32_t address = bytes[3];
            NSNumber *type = @(bytes[18]);
            [[SysSetting shareSetting] updateDeviceMessageWithName:[SysSetting shareSetting].currentUserName pwd:[SysSetting shareSetting].currentUserPassword deviceAddress:@(address) version:nil type:type mac:macAddress];
        }
    }
}

- (void)startConnectMesh{
    [centraManager startScanWithName:kSettingLastName Pwd:kSettingLastPwd AutoLogin:YES];
}

- (void)startConnectCurrentOTADevice{
    centraManager.isAutoLogin = YES;
    [centraManager connectWithItem:self.otaDevice];
}

- (void)saveMeshState{
    NSDictionary *dict = @{@"meshState":@(MeshOTAState_continue),@"address":@(self.otaDevice.u_DevAdress >> 8),@"deviceType":@(self.deviceType)};
    [[NSUserDefaults standardUserDefaults] setObject:dict forKey:kSaveMeshOTADictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearMeshState{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSaveMeshOTADictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)hasMeshStateData{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kSaveMeshOTADictKey];
    return dict != nil;
}

- (NSDictionary *)getSaveMeshStateData{
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kSaveMeshOTADictKey];
    return dict;
}

///查询当前是否处在meshOTA
- (BOOL)isMeshOTAing{
    return self.meshState != MeshOTAState_no;
}

///设置是否处理mac地址的notify回包(bytes[7] == 0xe1),因为meshAdd时，会收到大量不需要处理的mac回包。
- (void)setHandleMacNotify:(BOOL)able{
    _canHanbleMacNotify = able;
}

/*
 1.查询meshOTA状态
 2.进入mesh OTA状态
 */
- (void)startMeshOTA{
    self.singleOTAFinish = NO;
    self.otaDevice = centraManager.selConnectedItem;
    
    //1.查询
    [[BTCentralManager shareBTCentralManager] readMeshOTAState];
}

- (void)sendOTAPacket{
    kEndTimer(self.otaTimer)
    if(self.location < 0) return;
    self.singleOTAStart = YES;
    NSUInteger packLoction;
    NSUInteger packLength;
    if (self.location + 1 == self.number) {
        packLength = 0;
    }else if(self.location + 1 == self.number - 1){
        packLength = [self.otaData length] - self.location * 16;
    }else{
        packLength = 16;
    }
    packLoction = self.location * 16;
    
    NSLog(@"self.location = %d ;self.number = %d ;packLoction = %d ;packLoction = %d;",self.location,self.number,packLoction,packLength);
    
    NSRange range = NSMakeRange(packLoction, packLength);
    if (self.location + 1 == self.number) {
        //最后一个包特殊处理
        NSData *sendData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
        if ([centraManager canSendPack]) {
            [centraManager sendPack:sendData];
            _singleOTAFinish = YES;
        }else{
            //0.3秒后尝试
            [self performSelector:@selector(sendOTAPacket) withObject:nil afterDelay:0.3];
            return;
        }
    } else {
        if (self.location >= self.number) {
            _singleOTAFinish = YES;
            if (self.finishBlock) {
                self.finishBlock(0, 0);
            }
            return;
        }
        if ([centraManager canSendPack]) {
            NSData *sendData = [self.otaData subdataWithRange:range];
            [centraManager sendPack:sendData];
        }else{
            //0.3秒后尝试
            [self performSelector:@selector(sendOTAPacket) withObject:nil afterDelay:0.3];
            return;
        }
    }
    self.location ++;
//    NSString *t = [NSString stringWithFormat:@"正在传输ota包: %ld%%", self.location * 100 / self.number];
//    ARShowTips.shareTips.showTip(t);
    if (self.progressBlock) {
        self.progressBlock(MeshOTAState_normal, self.location * 100 / self.number);
    }
    
    if ((self.location * 16) % kMeshOTAPicketSize == 0 && packLoction != 0) {
        [kCentralManager readFeatureOfselConnectedItem];
        self.waitFirmware = YES;
    }else if (self.location != self.number){
        //注意：index=0与index=1之间的时间间隔修改为300ms，让固件有充足的时间进行ota配置。
        NSTimeInterval timeInterval = kSendOTAInterval;
        if (self.location == 1) {
            timeInterval = 0.3;
        }
        self.otaTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(sendOTAPacket) userInfo:nil repeats:YES];
    }
}

- (void)showMeshOTAResult{
//    ARShowTips.shareTips.delayHidden(0);
    
    NSInteger successNumber = 0;
    NSInteger failNumber = 0;
    for (DeviceModel *device in self.oldDevices) {
        NSNumber *oldAddress = @(device.u_DevAdress >> 8);
        NSInteger selectType = self.deviceType;
        NSInteger oldType = [[SysSetting getProductuuidWithDeviceAddress:device.u_DevAdress >> 8] integerValue];
        if (oldType == selectType && device.stata != LightStataTypeOutline) {
            for (DeviceModel *newDevice in self.devices) {
                NSNumber *newAddress = @(newDevice.u_DevAdress >> 8);
                if ([oldAddress isEqualToNumber:newAddress]) {
                    NSString *oldstring = device.versionString;
                    NSString *newString = newDevice.versionString;
                    //app杀掉，重启，如果原来是meshOTA的广播阶段，将获取不到OTAData，[self getBinVersionString].length = 0
                    if (oldstring.length == 0 || ![oldstring isEqualToString:[self getBinVersionString]]) {
                        if (![oldstring isEqualToString:newString]) {
                            successNumber ++;
                        }else{
                            failNumber ++;
                        }
                    }
                    break;
                }
            }
        }
    }
    if (self.finishBlock) {
        self.finishBlock(successNumber, failNumber);
    }
    //OTA完成，初始化参数
    [self stopMeshOTA];
}

- (NSInteger)number {
    NSUInteger len = self.otaData.length;
    BOOL ret = (NSInteger)(len %16);
    return !ret?((NSInteger)(len/16)+1):((NSInteger)(len/16)+2);
}

- (NSString *)getBinVersionString{
    NSMutableString *mstr = [NSMutableString string];
    if (self.otaData) {
        Byte *byte = (Byte *)[self.otaData bytes];
        for (int i = 2; i<6; i++) {
            [mstr appendFormat:@"%c",byte[i]];
        }
        [mstr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return mstr;
}

- (void)saveVersionString:(NSString *)string toDeviceAddress:(NSInteger )deviceAddress isOldArray:(BOOL)isOld{
    if (isOld) {
        for (DeviceModel *model in self.oldDevices) {
            NSNumber *address = @(model.u_DevAdress >> 8);
            if (address.integerValue == deviceAddress) {
                model.versionString = string;
                break;
            }
        }
    }
    for (DeviceModel *device in self.devices) {
        if (device.u_DevAdress >> 8 == deviceAddress) {
            device.versionString = string;
            NSDictionary *tem = @{
                                  Address : @(deviceAddress),
                                  Mac : [SysSetting getMacWithDeviceAddress:deviceAddress],
                                  Productuuid : [SysSetting getProductuuidWithDeviceAddress:deviceAddress],
                                  Version : string
                                  };
            [[SysSetting shareSetting] addDevice:YES Name:[SysSetting shareSetting].currentUserName pwd:[SysSetting shareSetting].currentUserPassword devices:@[tem]];
            break;
        }
    }
}

- (NSInteger)getOnlineDeviceNumberOfDeviceType:(NSInteger )deviceType{
    NSInteger number = 0;
    //获取当前设备状态列表
    for (DeviceModel *device in self.devices) {
        if ([[SysSetting getProductuuidWithDeviceAddress:device.u_DevAdress >> 8] isEqualToNumber:@(deviceType)] && device.stata != LightStataTypeOutline) {
            number ++;
        }
    }
//    NSLog(@"需要获取版本号的设备个数=%ld",(long)number);
    return number;
}

@end
