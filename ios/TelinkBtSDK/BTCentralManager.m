/********************************************************************************************************
 * @file     BTCentralManager.m 
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
//  BTCentralManager.m
//  TelinkBlue
//
//  Created by Green on 11/14/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import "BTCentralManager.h"
#import "BTConst.h"
#import "BTDevItem.h"
#import "CryptoAction.h"
#import "DeviceModel.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "TranslateTool.h"    //需要导入到库里面


#define random(x) (rand()%x)
#define MaxSnValue  0xffffff
#define kLoginTimerout (2)

//扫描蓝牙回调，容错处理最大间隔时间(重置设备后，扫描蓝牙设备时，同一个设备回调两次，第一次广播数据为老短地址，第二次为新短地址)
#define kDidDiscoverPeripheralInterval  (0.5)
//扫描蓝牙回调，容错处理最大设备个数
#define kDidDiscoverPeripheralMaxCount  (30)

#define BTLog(A,B)

static NSUInteger addIndex;
static NSUInteger scanTime;
static NSUInteger getNotifytime;

//记录上一次发送非OTA包的时间
static NSTimeInterval commentTime;

@interface BTCentralManager() {
    CBCentralManager *centralManager;
    
    NSString *userName;
    NSString *userPassword;
    NSString *nUserName;
    NSString *nUserPassword;
    
    CBCharacteristic *commandFeature;
    CBCharacteristic *pairFeature;
    CBCharacteristic *notifyFeature;
    CBCharacteristic *otaFeature;
    CBCharacteristic *fireWareFeature;
    
    uint8_t loginRand[8];
    uint8_t sectionKey[16];
    
@public
    uint8_t *_TBuffer;
    
    int snNo;
    int connectTime;
    NSInteger currSetIndex;
    
    BOOL isSetAll;
    BOOL isNeedScan;
    BOOL isEndAllSet;
    NSMutableArray *srcDevArrs;
    NSMutableArray *IdentifersArrs;
    BTDevItem *disconnectItem;
    NSUInteger otaPackIndex;
    
    uint8_t tempbuffer[20];
    BOOL flags;
    NSTimer *scanTimer;
    NSTimer *getNotifyTimer;
    NSTimer *connectTimer;
    NSThread    *_delayThread;
    
}

@property (nonatomic, strong) dispatch_source_t clickTimer;

@property (nonatomic, assign) NSTimeInterval containCYDelay;
@property (nonatomic, assign) NSTimeInterval exeCMDDate;
@property (nonatomic, assign) NSTimeInterval clickDate;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userPassword;
@property (nonatomic, assign, getter=isNeedScan) BOOL isNeedScan;
@property (nonatomic, strong) CBCharacteristic *commandFeature;
@property (nonatomic, strong) CBCharacteristic *pairFeature;
@property (nonatomic, strong) CBCharacteristic *otaFeature;
@property (nonatomic, strong) CBCharacteristic *fireWareFeature;
@property (nonatomic, assign) NSInteger currSetIndex;
@property (nonatomic, strong) NSString *nUserName;
@property (nonatomic, strong) NSString *nUserPassword;
@property (nonatomic, strong) CBCharacteristic *notifyFeature;
@property (nonatomic, assign, getter=isEndAllSet) BOOL isEndAllSet;
@property (nonatomic, strong) NSMutableArray *srcDevArrs;
@property (nonatomic, strong) NSMutableArray *IdentifersArrs;
@property (nonatomic, strong) NSMutableArray *discoverPeripheralArrs;
@property (nonatomic, assign) int snNo;
@property (nonatomic, assign, getter=isSetAll) BOOL isSetAll;
@property (nonatomic, assign)uint8_t *roadbytes;
@property (nonatomic, strong)BTDevItem *disconnectItem;
@property (nonatomic, strong)NSString *UUIDStr;
@property (nonatomic, assign)BOOL flags;
@property (nonatomic, strong)NSTimer *scanTimer;
@property (nonatomic, strong)NSTimer *getNotifyTimer;
@property (nonatomic, strong)NSTimer *connectTimer;
@property (nonatomic, strong)NSTimer *loginTimer;

@property (nonatomic, assign) BTStateCode stateCode;
@property (nonatomic, assign) BOOL isCanReceiveAdv;
@property (nonatomic, assign) int readIndex;

@property (nonatomic, strong) NSThread *writeLocationThread;

@end

@implementation BTCentralManager
@synthesize centralManager=_centralManager;
@synthesize userName;
@synthesize userPassword;
@synthesize isNeedScan;
@synthesize commandFeature;
@synthesize pairFeature;
@synthesize currSetIndex;
@synthesize nUserName;
@synthesize nUserPassword;
@synthesize notifyFeature;
@synthesize otaFeature;
@synthesize fireWareFeature;
@synthesize isEndAllSet;
@synthesize srcDevArrs;
@synthesize IdentifersArrs;
@synthesize selConnectedItem=_selConnectedItem;
@synthesize isAutoLogin;
@synthesize snNo;
@synthesize isSetAll;
@synthesize disconnectItem;
@synthesize flags;
@synthesize scanTimer;
@synthesize getNotifyTimer;
@synthesize  connectTimer;

-(void)initData {
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
    self.srcDevArrs=[[NSMutableArray alloc] init];
    self.IdentifersArrs = [[NSMutableArray alloc]init];
    self.discoverPeripheralArrs = [[NSMutableArray alloc]init];
    self.isNeedScan=NO;
    _isConnected=NO;
    _centerState=CBCentralManagerStateUnknown;
    _operaType=DevOperaType_Normal;
    self.currSetIndex=NSNotFound;
    memset(sectionKey, 0, 16);
    srand((int)time(0));
    self.snNo=random(MaxSnValue);
    otaPackIndex = 0;
    memset(tempbuffer, 0, 20);
    commentTime = 0;
    
    //创建常驻线程，用于写数据到沙盒
    _writeLocationThread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [_writeLocationThread start];
}

#pragma mark - Private
- (void)startThread{
    [NSTimer scheduledTimerWithTimeInterval:[[NSDate distantFuture] timeIntervalSinceNow] target:self selector:@selector(nullFunc) userInfo:nil repeats:NO];
    while (1) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)nullFunc{}

//初始化连接状态
-(void)reInitData{
    _isLogin=NO;
    _isConnected=NO;
    otaPackIndex = 0;
    self.isEndAllSet=NO;
    self.commandFeature=nil;
    self.pairFeature=nil;
    self.notifyFeature=nil;
    self.fireWareFeature = nil;
    self.otaFeature = nil;
    _operaStatus=DevOperaStatus_Normal;
    memset(loginRand,0, 8);
    memset(sectionKey,0, 16);
}

-(int)getNextSnNo{
    snNo++;
    if (snNo>MaxSnValue)
        snNo=1;
    return self.snNo;
}

-(uint32_t)getIntValueByHex:(NSString *)getStr{
    NSScanner *tempScaner=[[NSScanner alloc] initWithString:getStr];
    uint32_t tempValue;
    [tempScaner scanHexInt:&tempValue];
    return tempValue;
}

- (BTDevItem *)getItemWithTag:(NSString *)getStr withAddress:(uint32_t)add {
    BTDevItem *result=nil;
    for (BTDevItem *tempItem in srcDevArrs)
    {
        if ([tempItem.devIdentifier isEqualToString:getStr])
        {
            if (tempItem.u_DevAdress == add) {
                result=tempItem;
            }
            
            break;
        }
    }
    return result;
}

-(BTDevItem *)getDevItemWithPer:(CBPeripheral *)getPer{
    BTDevItem *result=nil;
    for (BTDevItem *tempItem in srcDevArrs)
    {
        if ([tempItem.blDevInfo isEqual:getPer])
        {
            result=tempItem;
            break;
        }
    }
    return result;
}

-(void)writeValue:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer Len:(int)len response:(CBCharacteristicWriteType)type {
    if (!characteristic)
        return;
    
    if (!self.selConnectedItem)
        return;
    
    if (self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected)
        return;
    
    NSData *tempData=[NSData dataWithBytes:buffer length:len];
    [self.selConnectedItem.blDevInfo writeValue:tempData forCharacteristic:characteristic type:type];
}

/**
 *setNodeGroupAddr
 
 */
-(void)setNodeGroupAddr :(uint32_t)u_DevAddress groupAddress:(NSInteger) groupAddress toDel:(BOOL) toDel
{
    uint8_t cmd[13]={0x11,0x11,0x11,0x00,0x00,0x66,0x00,0xd7,0x11,0x02,0x00,0x01,0x00};
    cmd[5]=u_DevAddress & 0xff;
    cmd[6]=(u_DevAddress>>8) & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    cmd[10] = toDel ? 0 : 1;
    cmd[11]=groupAddress & 0xff;
    cmd[12]=(groupAddress>>8) & 0xff;
    
    addIndex++;
    [self logByte:cmd Len:13 Str:@"setNodeGroupAddr"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
}

-(void)readValue:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer{
    if (!characteristic)
        return;
    
    if (!self.selConnectedItem)
        return;
    
    if (self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected)
        return;
    
    [self.selConnectedItem.blDevInfo readValueForCharacteristic:characteristic];
}

- (void)logByte:(uint8_t *)bytes Len:(int)len Str:(NSString *)str{
    NSMutableString *tempMStr=[[NSMutableString alloc] init];
    for (int i=0;i<len;i++)
        [tempMStr appendFormat:@"%0x ",bytes[i]];
    NSLog(@"%@ == %@",str,tempMStr);
}

-(void)pasterData:(uint8_t *)buffer IsNotify:(BOOL)isNotify{
    
    uint8_t sec_ivm[8];
    uint32_t tempMac=self.selConnectedItem.u_Mac;
    
    sec_ivm[0]=(tempMac>>24) & 0xff;
    sec_ivm[1]=(tempMac>>16) & 0xff;
    sec_ivm[2]=(tempMac>>8) & 0xff;
    
    memcpy(sec_ivm+3, buffer, 5);
    
    if (!(buffer[0]==0 && buffer[1]==0 && buffer[2]==0))
    {
        if ([CryptoAction decryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+5 MicLen:2 Ps:buffer+7 Len:13]){
            NSLog(@"解密返回成功");
        }else{
            NSLog(@"解密返回失败");
        }
    }
    if (isNotify)
        [self sendDevNotify:buffer];
    else
        [self sendDevCommandReport:buffer];
}

-(BTDevItem *)getNextItemWith:(BTDevItem *)getItem{
    if (srcDevArrs.count<2)
        return nil;
    
    BTDevItem *resultItem=nil;
    for (BTDevItem *tempItem in srcDevArrs)
    {
        if (tempItem==getItem)
            continue;
        resultItem=tempItem;
        break;
    }
    
    return resultItem;
}


#pragma  mark - Send Notify
-(void)sendDevChange:(BTDevItem *)item Flag:(DevChangeFlag)flag{
    if (_delegate && [_delegate respondsToSelector:@selector(OnDevChange:Item:Flag:)])
    {
        [_delegate OnDevChange:self Item:item Flag:flag];
    }
    //为了静默meshOTA，新增通知
    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
    mDict[@"sender"] = self;
    if(item) mDict[@"item"] = item;
    mDict[@"flag"] = @(flag);
    [[NSNotificationCenter defaultCenter] postNotificationName:kOnDevChangeNotify object:nil userInfo:mDict];
}

-(void)sendDevNotify:(uint8_t *)bytes{
    [self logByte:bytes Len:20 Str:@"Notify"];
    
    if (_delegate && [_delegate respondsToSelector:@selector(OnDevNotify:Byte:)])
    {
        [_delegate OnDevNotify:self Byte:bytes];
    }
    
    //为了静默meshOTA，新增通知
    [[NSNotificationCenter defaultCenter] postNotificationName:kOnDevNotifyNotify object:nil userInfo:@{@"sender":self,@"data":[NSData dataWithBytes:bytes length:20]}];
    
    [self passUsefulMessageWithBytes:bytes];
}

-(void)passUsefulMessageWithBytes:(uint8_t *)bytes{
    //灯的显示状态解析
    DeviceModel *firstItem = [self getFristDeviceModelWithBytes:bytes];
    
    if ([_delegate respondsToSelector:@selector(notifyBackWithDevice:)]) {
        [_delegate notifyBackWithDevice:firstItem];
    }
    DeviceModel *secondItem = [self getSecondDeviceModelWithBytes:bytes];
    if ([_delegate respondsToSelector:@selector(notifyBackWithDevice:)]) {
        [_delegate notifyBackWithDevice:secondItem];
    }
    
    if (bytes[8]==0x11 && bytes[9]==0x02 && bytes[7] == 0xe1) {
        uint32_t address = [self analysisedAddressAfterSettingWithBytes:bytes];
        if ([_delegate respondsToSelector:@selector(resultOfReplaceAddress:)]) {
            [self printContentWithString:[NSString stringWithFormat:@"change address back: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
            [self logByte:bytes Len:20 Str:@"Setting_Address"];
            [_delegate resultOfReplaceAddress:address];
        }
    }else if (bytes[8]==0x11 && bytes[9]==0x02 && bytes[7] == 0xe9){
        int year1 = bytes[10] & 0xFF;
        int year2 = bytes[11] & 0xFF;
        int year = (year1 << 8) + year2;
        if (year1 > year2) {
            year = (year2 << 8) + year1;
        }
        int month = (bytes[12] & 0xFF);
        int day = bytes[13] & 0xFF;
        int hour = bytes[14] & 0xFF;
        int minute = bytes[15] & 0xFF;
        int second = bytes[16] & 0xFF;
        NSString *str = [NSString stringWithFormat:@"%d-%d-%d %d:%d:%d",year,month,day,hour,minute,second];
        NSLog(@"[CoreBluetoothh] time %@",str);
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];// 创建一个时间格式化对象
        [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; //设定时间的格式
        NSDate *tempDate = [dateFormatter dateFromString:str];//将字符串转换为时间对象
        
        if ([_delegate respondsToSelector:@selector(getDevDate:)]) {
            [_delegate getDevDate:tempDate];
        }
    }else if (bytes[8]==0x11 && bytes[9]==0x02 && bytes[7] == 0xd4){
        NSLog(@"[CoreBluetoothh] address %@",[[self changeCommandToArray:bytes len:20] componentsJoinedByString:@"-"]);
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        int length = 20;
        int position = 10;
        int address;
        
        while (position < length) {
            address = bytes[position++];
            address = address & 0xFF;
            
            if (address == 0xFF)
                break;
            
            address = address | 0x8000;
            NSLog(@"[CoreBluetoothh] address = %d",address);
            [arr addObject:[NSNumber numberWithInt:address]];
        }
        
        if ([_delegate respondsToSelector:@selector(onGetGroupNotify:)]) {
            [_delegate onGetGroupNotify:arr];
        }
    }else if (bytes[8]==0x11 && bytes[9]==0x02 && bytes[7] == 0xe7){
        //        int total = bytes[20 - 1] & 0xFF;
        //        if (total == 0); //return nil;
        //        int offset = 1;
        //        int index = bytes[offset++];
        //        uint8_t *data[] = (byte) (bytes[offset] & 0xFF);
        //        int sceneId = params[params.length - 2];
        //
        //        int action = NumberUtils.byteToInt(data, 0, 3);
        //        int type = NumberUtils.byteToInt(data, 4, 6);
        //        int status = data >> 7 & 0x01;
        //        long time = NumberUtils.bytesToLong(params, 3, 5);
    }
}

-(void)sendDevCommandReport:(uint8_t *)bytes
{
    if (_delegate && [_delegate respondsToSelector:@selector(OnDevCommandReport:Byte:)])
    {
        [_delegate OnDevCommandReport:self Byte:bytes];
    }
}

-(void)sendDevOperaStatusChange:(OperaStatus)oStatus
{
    if (_delegate && [_delegate respondsToSelector:@selector(OnDevOperaStatusChange:Status:)])
    {
        [_delegate OnDevOperaStatusChange:self Status:oStatus];
    }
}


#pragma mark - SetNameAndPassword
- (void)setNewNetworkDataPro {
    [self printContentWithString:[NSString stringWithFormat:@"ready set new mesh: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    self.readIndex = 0;
    self.operaStatus=DevOperaStatus_SetName_Start;
    [CryptoAction  getNetworkInfo:buffer Opcode:4 Str:self.nUserName Psk:sectionKey];
    //    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    
    self.operaStatus=DevOperaStatus_SetPassword_Start;
    memset(buffer, 0, 20);
    [CryptoAction  getNetworkInfo:buffer Opcode:5 Str:self.nUserPassword Psk:sectionKey];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    //    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    self.operaStatus=DevOperaStatus_SetLtk_Start;
    [CryptoAction  getNetworkInfoByte:buffer Opcode:6 Str:tempbuffer Psk:sectionKey];
    //    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
}

/**
 for new model
 */
- (void)updateMeshInfo:(NSString *)nname password:(NSString *)npasword {
    self.nUserName = nname;
    self.nUserPassword = npasword;
    [self configueMeshForNewModel];
}

- (void)configueMeshForNewModel {
    uint8_t buffer[20];
    memset(buffer, 0, 20);
    self.readIndex = 0;
    self.operaStatus=DevOperaStatus_SetName_Start;
    [CryptoAction  getNetworkInfo:buffer Opcode:4 Str:self.nUserName Psk:sectionKey];
    //    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    
    self.operaStatus=DevOperaStatus_SetPassword_Start;
    memset(buffer, 0, 20);
    [CryptoAction  getNetworkInfo:buffer Opcode:5 Str:self.nUserPassword Psk:sectionKey];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    //    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    
    self.operaStatus=DevOperaStatus_SetLtk_Start;
    [CryptoAction  getNetworkInfoByte:buffer Opcode:6 Str:tempbuffer Psk:sectionKey];
    buffer[17] = 1;
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
}

-(void)setNewNetworkName:(NSString *)nName Pwd:(NSString *)nPwd ltkBuffer:(uint8_t *)buffer
{
    if (srcDevArrs.count<1)
        return;
    self.isSetAll = YES;
    
    self.nUserName=nName;
    self.nUserPassword=nPwd;
    _operaType=DevOperaType_Set;
    self.currSetIndex=NSNotFound;
    
    for (BTDevItem *tempItem in srcDevArrs)
        tempItem.isSeted=NO;
    
    self.isEndAllSet=NO;
    
    [self setNewNetworkNextPro];
    
    if (buffer != nil) {
        for (int i = 0;  i < 20 ; i++) {
            tempbuffer[i] = buffer[i];
        }
    }
    
}

-(void)setOut_Of_MeshWithName:(NSString *)addName PassWord:(NSString *)addPassWord NewNetWorkName:(NSString *)nName Pwd:(NSString *)nPwd ltkBuffer:(uint8_t *)buffer ForCertainItem:(BTDevItem *)item {
    if (!item) {
        return;
    }
    self.isSetAll = NO;
    self.nUserName=nName;
    self.nUserPassword=nPwd;                      //加灯时候的passwordnUserPassword
    self.userName = addName;
    self.userPassword = addPassWord;
    if (![_selConnectedItem isEqual:item]) {
        [self stopConnected];
    }
    _operaType = DevOperaType_Set;
    
    if (buffer != nil) {
        for (int i = 0;  i < 20 ; i++) {
            tempbuffer[i] = buffer[i];
        }
    }
    [self printContentWithString:[NSString stringWithFormat:@"change mesh name and set ltk: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    if (self.isLogin){
        [self setNewNetworkDataPro];
    }else{
        [self setNewNetworkWithItem:item];
    }
}

-(void)setNewNetworkName:(NSString *)nName Pwd:(NSString *)nPwd WithItem:(BTDevItem *)item ltkBuffer:(uint8_t *)buffer{
    if (!item)
        return;
    self.isSetAll=NO;
    
    self.nUserName=nName;
    self.nUserPassword=nPwd;
    if ([[item u_Name]isEqualToString:@"out_of_mesh"]&& self.scanWithOut_Of_Mesh == YES) {
        self.userName = @"out_of_mesh";
        self.userPassword = @"123";
    }
    _operaType=DevOperaType_Set;
    if (![_selConnectedItem isEqual:item])
        [self stopConnected];
    if (buffer != nil) {
        for (int i = 0;  i < 20 ; i++) {
            tempbuffer[i] = buffer[i];
        }
    }
    [self printContentWithString:[NSString stringWithFormat:@"change mesh name and ltk: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    if (self.isLogin){
        [self setNewNetworkDataPro];
    }else{
        [self setNewNetworkWithItem:item];
    }
}

-(void)setNewNetworkNextPro{
    BTDevItem *tempItem=nil;
    if (currSetIndex==NSNotFound)
    {
        if (_selConnectedItem)
        {
            tempItem=_selConnectedItem;
            currSetIndex=-1;
        }
        else
            currSetIndex=0;
    }
    
    if (!tempItem)
    {
        [self stopConnected];
        while (true){
            if (currSetIndex>=0 && currSetIndex<srcDevArrs.count){
                tempItem=srcDevArrs[currSetIndex];
            }
            else
                break;
            if (!tempItem.isSeted)
                break;
            currSetIndex++;
        }
        _selConnectedItem=tempItem;
    }
    
    if (!tempItem){
        self.isEndAllSet=YES;
        self.operaStatus=DevOperaStatus_SetNetwork_Finish;
        return;
    }
    
    if ((currSetIndex+1)==srcDevArrs.count)
        self.isEndAllSet=YES;
    
    [self setMeshNameAndPwdAndLtk:tempItem];
    
    currSetIndex++;
}

/**
 *有时会出现setItem的值相同的情况
 */
-(void)setMeshNameAndPwdAndLtk:(BTDevItem *)setItem{
    self.flags = YES;
    setItem.isSeted=YES;
    _selConnectedItem=setItem;
    for (int i=0; i<srcDevArrs.count; i++) {
        NSLog(@"[CoreBluetooth] srcDevArrs -> %@", [srcDevArrs[i] blDevInfo]);
    }
    
    [self connectPeripheral:[setItem blDevInfo]];
    
    NSLog(@"[CoreBluetooth] setMeshNameAndPwdAndLtk: -> %@", [setItem blDevInfo]);
}

-(void)setNewNetworkWithItem:(BTDevItem *)setItem{
    _selConnectedItem=setItem;
    self.flags = YES;
    setItem.isSeted=YES;
    
    for (int i=0; i<srcDevArrs.count; i++) {
        NSLog(@"[CoreBluetooth] srcDevArrs -> %@", [srcDevArrs[i] blDevInfo]);
    }
    [self connectPeripheral:[setItem blDevInfo]];
    NSLog(@"[CoreBluetooth] setNewNetworkWithItem: -> %@", [setItem blDevInfo]);
}

- (void)connectPeripheral:(CBPeripheral *)peripheral{
    //注意：调用连接，当前剩余的扫描回调缓存的设备无需处理
    [self cancelHandleDiscoverPeripheral];
    
    [self.centralManager connectPeripheral:peripheral
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (void)stopConnected {
    self.stateCode = BTStateCode_Normal;
    NSMutableArray *pers = [[NSMutableArray alloc] init];
    for (int i=0; i<srcDevArrs.count; i++) {
        [pers addObject:[srcDevArrs[i] blDevInfo].identifier.UUIDString];
    }
    //防止多个连接
    CBUUID *uuid =  [CBUUID UUIDWithString:BTDevInfo_ServiceUUID];
    NSArray <CBPeripheral *>*arr =[_centralManager retrieveConnectedPeripheralsWithServices:@[uuid]];
    NSMutableArray *peruuids = [[NSMutableArray alloc] init];
    for (int j=0; j<arr.count; j++) {
        [peruuids addObject:arr[j].identifier.UUIDString];
    }
    if (arr.count) {
        for (CBPeripheral *peripheral in arr) {
            if (peripheral.state==CBPeripheralStateConnected||
                peripheral.state==CBPeripheralStateConnecting) {
                [_centralManager cancelPeripheralConnection:peripheral];
            }
        }
    }
    _selConnectedItem=nil;
    [self reInitData];
}

-(NSString *)replaceStr:(NSString *)resStr TagStr:(NSString *)tagStr WithStr:(NSString *)rStr{
    if CheckStr(resStr)
        return @"";
    if CheckStr(tagStr)
        return resStr;
    if (!rStr)
        return resStr;
    
    NSRange tempRan=NSMakeRange(0, resStr.length);
    resStr=[resStr stringByReplacingOccurrencesOfString:tagStr withString:rStr options:0 range:tempRan];
    return resStr;
}

-(void)setNotifyOpenProSevervalTimes{
    if (getNotifytime < 3) {
        [self setNotifyOpenPro];
        getNotifytime++;
    }else{
        getNotifytime = 0;
        [self.getNotifyTimer invalidate];
    }
}

//获取灯的状态数据
-(void)setNotifyOpenPro
{
    if (!self.isConnected) {
        return;
    }
    NSLog(@"获取灯的状态");
    uint8_t buffer[1]={1};
    [self writeValue:self.notifyFeature Buffer:buffer Len:1 response:CBCharacteristicWriteWithResponse];
}


#pragma mark - BlueDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    _centerState = (CBCentralManagerState)central.state;
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        
        if (isNeedScan)
            [self startScanWithName:self.userName Pwd:self.userPassword];
    }else if (central.state==CBCentralManagerStatePoweredOff){
        [self stopConnected];
        [self stopScan];
    }
    if (_delegate && [_delegate respondsToSelector:@selector(OnCenterStatusChange:)]) {
        [_delegate OnCenterStatusChange:self];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
//        NSLog(@"didDiscoverPeripheral advertisementData -> %@", advertisementData);
    [self updateDidDiscoverPeripheralWithCentralManager:central didDiscoverPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    
}

- (void)updateDidDiscoverPeripheralWithCentralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    //RSSI为正数时，过滤掉，无需处理。
    NSInteger rssi = (NSInteger)[RSSI integerValue];
    if (rssi > 0) {
        return;
    }
    
    BOOL has = NO;
    NSDictionary *newDict = @{@"central":central,@"peripheral":peripheral,@"advertisementData":advertisementData,@"RSSI":RSSI};
    
    for (NSDictionary *dict in self.discoverPeripheralArrs) {
        CBPeripheral *oldP = dict[@"peripheral"];
        if ([oldP.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            [self.discoverPeripheralArrs replaceObjectAtIndex:[self.discoverPeripheralArrs indexOfObject:dict] withObject:newDict];
            has = YES;
            break;
        }
    }
    if (!has) {
        //容错逻辑优化：扫描到新设备才添加该设备的延时，且重复设备只替换。
        [self.discoverPeripheralArrs addObject:newDict];
        [self performSelector:@selector(handleFirstDidDiscoverPeripheral) withObject:nil afterDelay:kDidDiscoverPeripheralInterval];
    }
}

- (void)handleFirstDidDiscoverPeripheral{
    //容错逻辑优化：加锁，由于处理蓝牙扫描数据需要时间，防止多次延时同时进入，造成取数组元素异常。
    @synchronized(self) {
        if (self.discoverPeripheralArrs.count > 0) {
            //1.做法一：未加RSSI强度判断逻辑
//            NSDictionary *dict = self.discoverPeripheralArrs.firstObject;
            //2.做法二：添加RSSI强度判断逻辑
            NSDictionary *dict = self.discoverPeripheralArrs.firstObject;
            NSInteger macRSSI = (NSInteger)[self.discoverPeripheralArrs.firstObject[@"RSSI"] integerValue];
            for (NSDictionary *temDict in self.discoverPeripheralArrs) {
                NSInteger curRSSI = (NSInteger)[temDict[@"RSSI"] integerValue];
                if (macRSSI < curRSSI) {
                    macRSSI = curRSSI;
                    dict = temDict;
                }
//                NSString *logString = [NSString stringWithFormat:@"测试log：curRSSI=%ld,macRSSI=%ld",(long)curRSSI,(long)macRSSI];
//                NSLog(@"%@", logString);
//                [self printContentWithString:logString];
            }
            [self userHandleCentralManager:dict[@"central"] didDiscoverPeripheral:dict[@"peripheral"] advertisementData:dict[@"advertisementData"] RSSI:dict[@"RSSI"]];
            [self.discoverPeripheralArrs removeObject:dict];
        }
    }
}

- (void)cancelHandleDiscoverPeripheral{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleFirstDidDiscoverPeripheral) object:nil];
    });
    [self.discoverPeripheralArrs removeAllObjects];
//    NSString *logString = @"测试log：清理缓存的扫描蓝牙设备数据";
//    NSLog(@"%@", logString);
//    [self printContentWithString:logString];
}

- (void)userHandleCentralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    self.isCanReceiveAdv = YES;
    
    NSString *tempUserName=[advertisementData objectForKey:@"kCBAdvDataLocalName"]; //广播包名字LocalName
    BOOL scanContainOut_of_mesh = self.scanWithOut_Of_Mesh;
    BOOL scanOption1 = [tempUserName isEqualToString:self.userName];
    BOOL scanOption2 = [tempUserName isEqualToString:@"out_of_mesh"];
    BOOL options;
    //要求扫描out_of_mesh;
    if (scanContainOut_of_mesh) {
        options = scanOption1 || scanOption2;
    }
    //不要求扫描out_of_mesh;
    else{
        options = scanOption1;
    }
    if (!options) return; //不符合扫描过滤条件
    NSString *tempName=[peripheral name];
    NSString *tempParStr=[[advertisementData objectForKey:@"kCBAdvDataManufacturerData"] description];
    
    [self printContentWithString:[NSString stringWithFormat:@"kCBAdvDataManufacturerData :  %@\nRSSI=%@",advertisementData[@"kCBAdvDataManufacturerData"],RSSI]];
    NSLog(@"handle advertisementData -> %@ \nRSSI=%@", advertisementData,RSSI);
    if (tempParStr.length>=30){
        //Uid
        
        kEndTimer(self.loginTimer)
        
        NSRange tempRange=NSMakeRange(1, 4);
        NSString *tempStr=[tempParStr substringWithRange:tempRange];
        uint32_t tempVid=[self getIntValueByHex:tempStr];
        if (tempVid==BTDevInfo_UID) {
            NSString *tempUuid=[[peripheral identifier] UUIDString];
            [self.IdentifersArrs addObject:peripheral];
            //ios9--<11021102 2211ffff 11022211 ffff0500 010f0000 01020304 05060708 090a0b0c 0d0e0f>
            NSString *deviceAddStr = [tempParStr substringWithRange:NSMakeRange(tempParStr.length-41, 4)];
            uint32_t deviceAdd = (uint32_t)strtoul([deviceAddStr UTF8String], 0, 16);
            BTDevItem *tempItem=[self getItemWithTag:tempUuid withAddress:deviceAdd];
            NSLog(@"device.address:%04X -> %@",deviceAdd, deviceAddStr);
            BOOL isNew=NO;
            if (!tempItem) {
                isNew=YES;
                tempItem=[[BTDevItem alloc] init];
                [self.srcDevArrs addObject:tempItem];
            }
            tempItem.devIdentifier=[[peripheral identifier] UUIDString];
            tempItem.name=tempName;
            tempItem.blDevInfo=peripheral;
            tempItem.u_Name=tempUserName;
            tempItem.u_Vid=tempVid;
            tempItem.rssi=[RSSI intValue];
            
            tempRange=NSMakeRange(5, 4);
            tempStr=[tempParStr substringWithRange:tempRange];
            tempItem.u_meshUuid=[self getIntValueByHex:tempStr];
            
            tempRange=NSMakeRange(10, 8);
            tempStr=[tempParStr substringWithRange:tempRange];
            tempItem.u_Mac=[self getIntValueByHex:tempStr];
            NSLog(@"device.u_Mac:%08X -> %@",tempItem.u_Mac, tempStr);

            //PId
            if (tempParStr.length>=23) {
                tempRange=NSMakeRange(19, 4);
                tempStr=[tempParStr substringWithRange:tempRange];
                tempItem.u_Pid =[self getIntValueByHex:tempStr];
            }
            if (tempParStr.length>=25) {
                tempRange=NSMakeRange(23, 2);
                tempStr=[tempParStr substringWithRange:tempRange];
                tempItem.u_Status =[self getIntValueByHex:tempStr];
            }
            if (tempParStr.length>=41) {
                //目前了解ios 9.0以上时候
                
                tempRange=NSMakeRange(19, 4);
                NSString *tempString=[tempParStr substringWithRange:tempRange];
                if ([tempString isEqualToString:@"1102"]) {
                    tempRange=NSMakeRange(39, 2);
                    tempStr=[tempParStr substringWithRange:tempRange];
                    
                    tempStr = [NSString stringWithFormat:@"%@00",tempStr];
                    tempStr=[self replaceStr:tempStr TagStr:@" " WithStr:@""];
                    
                    if (tempParStr.length >= 36) {
                        NSRange Part1=NSMakeRange(32, 2);
                        NSRange Part2 = NSMakeRange(34, 2);
                        NSString *header = [tempParStr substringWithRange:Part1];
                        NSString *tailer = [tempParStr substringWithRange:Part2];
                        NSString *detailProductID = [NSString stringWithFormat:@"%@%@",tailer,header];
                        uint32_t ProductID = [self getIntValueByHex:detailProductID];
                        tempItem.productID = ProductID;
                    }
                }else{
                    tempStr=[self replaceStr:tempStr TagStr:@" " WithStr:@""];
                    tempItem.u_DevAdress =[self getIntValueByHex:tempStr];
                    tempRange=NSMakeRange(25, 5);
                    tempStr=[tempParStr substringWithRange:tempRange];
                    tempStr=[self replaceStr:tempStr TagStr:@" " WithStr:@""];
                    tempItem.u_DevAdress =[self getIntValueByHex:tempStr];
                    NSRange Part1=NSMakeRange(19, 2);
                    NSRange Part2 = NSMakeRange(21, 2);
                    NSString *header = [tempParStr substringWithRange:Part1];
                    NSString *tailer = [tempParStr substringWithRange:Part2];
                    NSString *detailProductID = [NSString stringWithFormat:@"%@%@",tailer,header];
                    uint32_t ProductID = [self getIntValueByHex:detailProductID];
                    tempItem.productID = ProductID;
                }
                tempItem.u_DevAdress =[self getIntValueByHex:tempStr];
                tempItem.u_DevAdress =((tempItem.u_DevAdress<<8) & 0xff00) + (tempItem.u_DevAdress>>8);
            }
            if (isNew) {
                scanTime = 0;          //扫描超时清零
                [self.scanTimer invalidate];
                self.scanTimer = nil;
                [self sendDevChange:tempItem Flag:DevChangeFlag_Add];
                NSString *tip = [NSString stringWithFormat:@"scaned new device with address: 0x%04x", tempItem.u_DevAdress];
                [self printContentWithString:tip];
                
                if ([_delegate respondsToSelector:@selector(scanResult:)]) {
                    [[BTCentralManager shareBTCentralManager]stopScan];
                    self.disconnectType = DisconectType_SequrenceSetting;
                    [_delegate scanResult:tempItem];
                }
            }
            if (srcDevArrs.count==1 && isAutoLogin) {
                //NSLog(@"AutoLogining");
                _operaType=DevOperaType_AutoLogin;
                [self stopConnected];
                [[BTCentralManager shareBTCentralManager].centralManager stopScan];
                [self connectPro];
                
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"[CoreBluetooth] 0.7 连接上设备的回调");
    [self.centralManager stopScan];
    [self.connectTimer invalidate];
    connectTime = 0;
    peripheral.delegate=self;
    _isConnected=YES;
    
    [self printContentWithString:[NSString stringWithFormat:@"did connect address: 0x%04x", self.selConnectedItem.u_DevAdress]];
    
    if (self.scanWithOut_Of_Mesh == YES) {
        BTDevItem *connectedItem = [[BTDevItem alloc]init];
        connectedItem.blDevInfo = peripheral;
        if (connectedItem)
            [self sendDevChange:connectedItem Flag:DevChangeFlag_Connected];
        
    }else if(self.scanWithOut_Of_Mesh == NO){
        BTDevItem *tempItem=[self getDevItemWithPer:peripheral];
        if (tempItem) {
            [self sendDevChange:tempItem Flag:DevChangeFlag_Connected];
        }
    }
    NSLog(@"[CoreBluetooth] 0.71 调用发现设备Service方法");
    
    kEndTimer(self.loginTimer)
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeScanServices) repeats:NO];
    [peripheral discoverServices:nil];
}

- (void)loginT:(NSTimer *)timer {
    
    TimeoutType type = [timer.userInfo intValue];
    [self stateCodeAndErrorCodeAnasisly:type];
    if ([self.delegate respondsToSelector:@selector(loginTimeout:)]) {
        [self.delegate loginTimeout:(TimeoutType)[timer.userInfo intValue]];
    }
    
    
    kEndTimer(timer)
}

- (void)stateCodeAndErrorCodeAnasisly:(TimeoutType)type {
    if (![self.delegate respondsToSelector:@selector(exceptionReport:errorCode: deviceID:)]) return;
    int add = 0;
    if (self.selConnectedItem) {
        add = self.selConnectedItem.u_DevAdress>>8;
    }
    switch (type) {
        case TimeoutTypeScanDevice:{
            BTErrorCode errorCode = BTErrorCode_UnKnow;
            if (_centerState != CBCentralManagerStatePoweredOn) {
                errorCode = BTErrorCode_BLE_Disable;
            }else{
                errorCode = self.isCanReceiveAdv ? BTErrorCode_NO_Device_Scaned : BTErrorCode_NO_ADV;
            }
            [self.delegate exceptionReport:BTStateCode_Scan errorCode:errorCode%100 deviceID:add];
        }   break;
        case TimeoutTypeConnectting: {
            [self.delegate exceptionReport:BTStateCode_Connect errorCode:BTErrorCode_Cannot_CreatConnectRelation%100 deviceID:add];
        }   break;
        case TimeoutTypeScanServices:
        case TimeoutTypeScanCharacteritics: {
            [self.delegate exceptionReport:BTStateCode_Connect errorCode:BTErrorCode_Cannot_ReceiveATTList%100 deviceID:add];
        }   break;
        case TimeoutTypeWritePairFeatureBack:{
            [self.delegate exceptionReport:BTStateCode_Login errorCode:BTErrorCode_WriteLogin_NOResponse%100 deviceID:add];
        }   break;
        case TimeoutTypeReadPairFeatureBack:{
            [self.delegate exceptionReport:BTStateCode_Login errorCode:BTErrorCode_ReadLogin_NOResponse%100 deviceID:add];
        }   break;
        case TimeoutTypeReadPairFeatureBackFailLogin:{
            [self.delegate exceptionReport:BTStateCode_Login errorCode:BTErrorCode_ValueCheck_LoginFail%100 deviceID:add];
        }   break;
        default:    break;
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"[CoreBluetooth] 0.7.2 连接设备失败的回调 %@ %ld", error, (long)error.code);
    
    //NSLog(@"Fail To Connect");
    [self reInitData];
    if (_operaType==DevOperaType_Set)
        [self setNewNetworkNextPro];
    else
    {
        BTDevItem *tempItem=[self getDevItemWithPer:peripheral];
        if (tempItem)
            [self sendDevChange:tempItem Flag:DevChangeFlag_ConnecteFail];
        
        if (isAutoLogin && [self.selConnectedItem.blDevInfo isEqual:peripheral])
        {
            _operaType=DevOperaType_AutoLogin;
            [self connectNextPro];
            //NSLog(@"ReConnecting Due TO Fail To Connect -%@",peripheral.description);
            
        }
    }
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"异常断开didDisconnectPeripheral%@,%@",error.localizedDescription,error.description);
    }
    BTDevItem *item = [self getDevItemWithPer:peripheral];
    [self printContentWithString:[NSString stringWithFormat:@"did disconnect address: 0x%04x", item.u_DevAdress]];
    NSLog(@"[CoreBluetooth] 0.7.2 设备断开连接 uuid:%@",peripheral.identifier.UUIDString);
    //防止刚刚连接成功就断开连接造成的异常
    [self cancleLoginSuccessAction];
    //对断开连接的灯进行设置
    if ([_delegate respondsToSelector:@selector(scanResult:)]) {
        [[BTCentralManager shareBTCentralManager] connectWithItem:item];
        [_delegate scanResult:item];
    }
    if ([_delegate respondsToSelector:@selector(settingForDisconnect:WithDisconectType:)]) {
        [_delegate settingForDisconnect:item WithDisconectType:DisconectType_SequrenceSetting];
    }
    self.disconnectType = DisconectType_Normal;
    [self reInitData];
    
    if (_operaType==DevOperaType_Set){
        [self selConnectedItem];
        if (self.flags == YES) {
            self.flags = NO;
        }else{
            //在添加逻辑：先扫描所有，选择添加设备，这个添加逻辑，下面的随机连接方法会造成异常。
            NSLog(@"[CoreBluetooth warning]注意：自动添加设备流程不会出现该log。");
            //            NSLog(@"[CoreBluetooth] 从设备断开连接的回调调用连接设备的方法");
            //            [self connectPro];
            //            NSLog(@"[CoreBluetooth] 从设备断开连接的回调调用连接设备的方法结束");
        }
    }else {
        BTDevItem *tempItem=[self getDevItemWithPer:peripheral];
        if (tempItem){
            [self sendDevChange:tempItem Flag:DevChangeFlag_DisConnected];
        }
        if (isAutoLogin && [self.selConnectedItem.blDevInfo isEqual:peripheral] && !self.scanWithOut_Of_Mesh){
            _operaType=DevOperaType_AutoLogin;
            [self scanconnect];
        }
    }
}

///取消登录成功后的相关操作
- (void)cancleLoginSuccessAction{
    //注意：登录成功后，为了错开发送数据包，0s、2s、4s发送setNotifyOpenPro，0.5s发送setTime，存在meshOTA功能的，1s发送readMeshOTAState。蓝牙连接异常断开时，上面定时器和延时都需要停止掉。
    kEndTimer(self.getNotifyTimer)
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setTime) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readMeshOTAState) object:nil];
    });
}

-(void)scanconnect{
    if ([_delegate respondsToSelector:@selector(resetStatusOfAllLight)]) {
        [_delegate resetStatusOfAllLight];
    }
    [self startScanWithName:self.userName Pwd:self.userPassword AutoLogin:YES];
    self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(calulateTime) userInfo:nil repeats:YES];
}

-(void)calulateTime{
    if (scanTime == 6) {
        [self.scanTimer invalidate];
        self.scanTimer = nil;
        
        if ([_delegate respondsToSelector:@selector(resetStatusOfAllLight)]) {
            [_delegate resetStatusOfAllLight];
        }
    }
}


#pragma mark - Peripheral Delegate
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral{
    NSLog(@"peripheralDidUpdateName 设备名称改变");
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"[CoreBluetooth] 0.80 发现到设备Service回调");
    self.operaStatus=DevOperaStatus_ScanSrv_Finish;
    if (error) {
        BTLog(@"扫描服务错误: %@", [error localizedDescription]);
        //        [self setNewNetworkNextPro];
        return;
    }
    
    for (CBService *tempSer in peripheral.services)
    {
        if ([tempSer.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_ServiceUUID]]){
            NSLog(@"[CoreBluetooth] 0.82 找到里面含有设备信息的Service，然后调用发现该Service的特征");
            [self printContentWithString:[NSString stringWithFormat:@"did discover services for address: 0x%04x", self.selConnectedItem.u_DevAdress]];
            [peripheral discoverCharacteristics:nil forService:tempSer];
            
            kEndTimer(self.loginTimer)
            self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeScanCharacteritics) repeats:NO];
        }
        if ([tempSer.UUID isEqual:[CBUUID UUIDWithString:Service_Device_Information]]) {
            [peripheral discoverCharacteristics:nil forService:tempSer];
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    NSLog(@"[CoreBluetooth] 0.9 找到服务的特征的回调");
    
    self.operaStatus=DevOperaStatus_ScanChar_Finish;
    if (error) {
        [self setNewNetworkNextPro];
        return;
    }
    [self printContentWithString:[NSString stringWithFormat:@"did discover characteristics for address: 0x%04x", self.selConnectedItem.u_DevAdress]];
    
    for (CBCharacteristic *tempCharac in service.characteristics)
    {
        if ([tempCharac.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Notify]])
        {
            [peripheral setNotifyValue:YES forCharacteristic:tempCharac];
            self.notifyFeature=tempCharac;
        }
        else if ([tempCharac.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Command]])
        {
            self.commandFeature=tempCharac;
        }
        else if ([tempCharac.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_Pair]])
        {
            NSLog(@"[CoreBluetooth]0.91 这个是写登录的特征值 %@ ", tempCharac);
            self.pairFeature = tempCharac;
            if (_operaType == DevOperaType_Set || _operaType == DevOperaType_AutoLogin){
                NSLog(@"[CoreBluetooth] 1.0 调用登录");
                [self loginWithPwd:self.userPassword];      //    self.userName = addName;//扫描
            }else{
                //解决重复调用登录
                if ([self.delegate respondsToSelector:@selector(scanedLoginCharacteristic)]) {
                    [self.delegate scanedLoginCharacteristic];
                }
            }
        }else if([tempCharac.UUID isEqual:[CBUUID UUIDWithString:BTDevInfo_FeatureUUID_OTA]]){
            self.otaFeature = tempCharac;
        }
        else if([tempCharac.UUID isEqual:[CBUUID UUIDWithString:Characteristic_Firmware]]){
            self.fireWareFeature = tempCharac;
            //            [peripheral readValueForCharacteristic:tempCharac];
        }
    }
    NSLog(@"[CoreBluetooth] pairFeature %@", self.pairFeature);
    
}

-(void)reloadState:(CBCharacteristic *)characteristic{
    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        BTLog(@"收到数据错误: %@", [error localizedDescription]);
        return;
    }
    if ([characteristic isEqual:self.pairFeature]) {
        
        NSLog(@"[CoreBluetooth] 1.3.1 pairFeature back");
        
        uint8_t *tempData=(uint8_t *)[characteristic.value bytes];
        
        if (_operaStatus==DevOperaStatus_Login_Start) {
            kEndTimer(self.loginTimer)
            if (!tempData) return;
            if (tempData[0]==13) {
                uint8_t buffer[16];
                
                NSLog(@"[CoreBluetooth] %d", (OperaStatus)DevOperaStatus_Login_Start);
                
                if ([CryptoAction encryptPair:self.userName
                                          Pas:self.userPassword
                                        Prand:tempData+1
                                      PResult:buffer]) {
                    [self logByte:buffer Len:16 Str:@"CheckBuffer"];
                    memset(buffer, 0, 16);
                    [CryptoAction getSectionKey:self.userName
                                            Pas:self.userPassword
                                         Prandm:loginRand
                                         Prands:tempData+1
                                        PResult:buffer];
                    
                    memcpy(sectionKey, buffer, 16);
                    [self logByte:buffer Len:16 Str:@"SectionKey"];
                    
                    _isLogin=YES;
                    self.stateCode = BTStateCode_Normal;
                    
                    if ([_delegate respondsToSelector:@selector(OnDevChange:Item:Flag:)]) {
                        [_delegate OnDevChange:self Item:[self getDevItemWithPer:peripheral] Flag:DevChangeFlag_Login];
                    }
                    //为了静默meshOTA，新增通知
                    BTDevItem *item = [self getDevItemWithPer:peripheral];
                    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
                    mDict[@"sender"] = self;
                    if(item) mDict[@"item"] = item;
                    mDict[@"flag"] = @(DevChangeFlag_Login);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kOnDevChangeNotify object:nil userInfo:mDict];
                    
                    if (!self.scanWithOut_Of_Mesh) {
                        //注意：登录成功后，为了错开发送数据包，0s、2s、4s发送setNotifyOpenPro，0.5s发送setTime，存在meshOTA功能的，1s发送readMeshOTAState。蓝牙连接异常断开时，上面定时器和延时都需要停止掉。
                        kEndTimer(self.getNotifyTimer)
                        self.getNotifyTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(setNotifyOpenProSevervalTimes) userInfo:nil repeats:YES];
                        [self.getNotifyTimer fire];
                        [self performSelector:@selector(setTime) withObject:nil afterDelay:0.5];
                    }
                }
            }else{
                if (self.stateCode == BTStateCode_Login){
                    [self stateCodeAndErrorCodeAnasisly:TimeoutTypeReadPairFeatureBackFailLogin];
                }
                
            }
            
            if (!_isLogin) {
                [self printContentWithString:[NSString stringWithFormat:@"login fail with address: 0x%04x", self.selConnectedItem.u_DevAdress]];
                [self stopConnected];//重置BUG
            }else{
                self.operaStatus=DevOperaStatus_Login_Finish;
                [self printContentWithString:[NSString stringWithFormat:@"login success with address: 0x%04x", self.selConnectedItem.u_DevAdress]];
            }
            if (_operaType==DevOperaType_Set)
            {
                if (_isLogin){
                    [self setNewNetworkDataPro];
                }else{
                    [self setNewNetworkNextPro];
                }
            }
        }
        else if (_operaStatus==DevOperaStatus_SetLtk_Start)
        {
            if (tempData[0]==7)
            {
                BTLog(@"%@",@"Set Success");
                _selConnectedItem.isSetedSuff=YES;
                //                if ([self.delegate respondsToSelector:@selector(setMeshInfoSuccessBack)]) {
                //                    [self.delegate setMeshInfoSuccessBack];
                //                }
            }
            if (isSetAll && !self.isEndAllSet)
                [self setNewNetworkNextPro];
            else
                self.operaStatus=DevOperaStatus_SetNetwork_Finish;
        }
    } else if ([characteristic isEqual:self.commandFeature]){
        
        NSLog(@"[CoreBluetooth] 1.3.2 commandFeature back");
        
        if (_isLogin){
            BTLog(@"%@",@"Command 数据解析");
            uint8_t *tempData=(uint8_t *)[characteristic.value bytes];
            [self pasterData:tempData IsNotify:NO];
        }
    } else if ([characteristic isEqual:self.notifyFeature]){
        
        NSLog(@"[CoreBluetooth] 1.3.3 notifyFeature back");
        
        BTLog(@"Recieve_Notify_Data%@",characteristic.value);
        if (_isLogin)
        {
            BTLog(@"%@",@"Notify_Data_Analyses");
            uint8_t *tempData=(uint8_t *)[characteristic.value bytes];
            [self pasterData:tempData IsNotify:YES];
            //打印log
            NSString *noti = [NSString stringWithFormat:@"notify back:%@",characteristic.value];
            //            if (noti.length>38) {
            //                NSString *h = [noti substringToIndex:26];
            //                NSString *l = [noti substringFromIndex:noti.length-12];
            //                noti = [NSString stringWithFormat:@"%@....%@",h,l];
            //            }
            [self printContentWithString:noti];
        }
    } else if ([characteristic isEqual:self.fireWareFeature]){
        
        NSLog(@"[CoreBluetooth] 1.3.4 fireWareFeature back");
        NSData *tempData = [characteristic value];
        BTDevItem *item= [self getDevItemWithPer:peripheral];
        
        if ([_delegate respondsToSelector:@selector(OnConnectionDevFirmWare:)] && tempData) {
            [_delegate OnConnectionDevFirmWare:tempData];
        }
        if ([_delegate respondsToSelector:@selector(OnConnectionDevFirmWare:Item:)]) {
            [_delegate OnConnectionDevFirmWare:tempData Item:item];
        }
        //为了静默MeshOTA，新增通知
        NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
        if(tempData) mDict[@"data"] = tempData;
        if(item) mDict[@"item"] = item;
        [[NSNotificationCenter defaultCenter] postNotificationName:kOnConnectionDevFirmWareNotify object:nil userInfo:mDict];
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error && ![characteristic isEqual:self.otaFeature]) {
        //NSLog(@"Write___Error: %@<--> %@", [error localizedFailureReason],[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
        return;
    }
    BTLog(@"%@",@"Write Successed");
    if ([characteristic isEqual:self.pairFeature]){
        self.readIndex++;
        BOOL read = NO;
        if (self.operaStatus == DevOperaStatus_SetName_Start || self.operaStatus == DevOperaStatus_SetPassword_Start|| self.operaStatus == DevOperaStatus_SetLtk_Start) {
            if (self.readIndex == 3) {
                read = YES;
            }
        }else{
            read = YES;
        }
        if (read) {
            [self.selConnectedItem.blDevInfo readValueForCharacteristic:self.pairFeature];
            kEndTimer(self.loginTimer)
            self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeReadPairFeatureBack) repeats:NO];
        }
    }
}


#pragma mark Public
-(void)startScanWithName:(NSString *)nStr Pwd:(NSString *)pwd{
    
    NSLog(@"[CoreBluetooth] 0 进入扫描设备方法");
    NSLog(@"[CoreBluetooth] Mesh -> %@, %@", nStr, pwd);
    [self stopScan];
    [self stopConnected];
    self.userName=nStr;
    self.userPassword=pwd;
    self.isNeedScan=YES;
//    if (_centerState == CBCentralManagerStatePoweredOn) {
        [self printContentWithString:@"ready scan devices "];
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
//    }
    kEndTimer(self.loginTimer)
    self.isCanReceiveAdv = NO;
    
    self.stateCode = BTStateCode_Scan;
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:ScanTimeout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeScanDevice) repeats:NO];
}

-(void)startScanWithName:(NSString *)nStr Pwd:(NSString *)pwd AutoLogin:(BOOL)autoLogin{
    self.isAutoLogin=autoLogin;
    [self startScanWithName:nStr Pwd:pwd];
}

-(void)stopScan{
    @synchronized (self) {
        if (self.selConnectedItem && self.selConnectedItem.blDevInfo && _isConnected) {
            NSMutableArray *pers = [[NSMutableArray alloc] init];
            for (int i=0; i<srcDevArrs.count; i++) {
                [pers addObject:[srcDevArrs[i] blDevInfo].identifier.UUIDString];
            }
            BOOL contain = NO;
            for (int jj=0; jj<pers.count; jj++) {
                if ([pers[jj] isEqualToString:self.selConnectedItem.blDevInfo.identifier.UUIDString]) {
                    contain = YES;
                    break;
                }
            }
            if (contain) {
                if (self.selConnectedItem.blDevInfo.state==CBPeripheralStateConnected||
                    self.selConnectedItem.blDevInfo.state==CBPeripheralStateConnecting) {
                    [_centralManager cancelPeripheralConnection:[self.selConnectedItem blDevInfo]];
                }
            }
        }
        _selConnectedItem=nil;
        [self.srcDevArrs removeAllObjects];
        [self.IdentifersArrs removeAllObjects];
        
        //优化：开发者频繁调用蓝牙扫描时，清理缓存设备数组残留的老设备
        [self cancelHandleDiscoverPeripheral];
        
        [self reInitData];
        [_centralManager stopScan];
    }
}

-(void)connectPro {
    if ([srcDevArrs count]<1)
        return;
    BTDevItem *item = nil;
    if ([srcDevArrs lastObject] == _selConnectedItem) {
        item = srcDevArrs[0];
    }else{
        item = [srcDevArrs lastObject];
    }
    
    //扫描连接的时候
    if ([item.u_Name isEqualToString:@"out_of_mesh"]&& self.scanWithOut_Of_Mesh == YES) {
        self.userName = @"out_of_mesh";
        self.userPassword = @"123";
    }
    _selConnectedItem=item;
    
    
    [self connectPeripheral:[item blDevInfo]];
    
    NSString *tip = [NSString stringWithFormat:@"send connect request for address: 0x%04x", self.selConnectedItem.u_DevAdress];
    [self printContentWithString:tip];
    NSLog(@"[CoreBluetooth] connectPro uuid:%@",self.selConnectedItem.blDevInfo.identifier.UUIDString);

    kEndTimer(self.loginTimer)
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeConnectting) repeats:NO];
}

-(void)connectNextPro{
    if ([srcDevArrs count]<2)
        return;
    
    BTDevItem *tempItem=[self getNextItemWith:self.selConnectedItem];
    if (!tempItem)
        return;
    [self printContentWithString:[NSString stringWithFormat:@"connect next device : 0x%04x", tempItem.u_DevAdress]];
    _selConnectedItem=tempItem;

    [self connectPeripheral:[tempItem blDevInfo]];
    
    NSLog(@"[CoreBluetooth] connectNextPro uuid:%@",tempItem.blDevInfo.identifier.UUIDString);
}

-(void)connectWithItem:(BTDevItem *)cItem{
    if (cItem.blDevInfo.state == CBPeripheralStateConnected ||
        cItem.blDevInfo.state == CBPeripheralStateConnecting) {
        return;
    }
    [self stopConnected];
    [self.centralManager stopScan];
    _operaType=DevOperaType_AutoLogin;
    if (!cItem)
        return;
    [self printContentWithString:[NSString stringWithFormat:@"connect device directly : 0x%04x", cItem.u_DevAdress]];
    _selConnectedItem=cItem;
    
    [self connectPeripheral:[cItem blDevInfo]];
    
    NSLog(@"[CoreBluetooth] connectWithItem: uuid:%@",self.selConnectedItem.blDevInfo.identifier.UUIDString);

    kEndTimer(self.loginTimer)
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeConnectting) repeats:NO];
}

-(void)loginWithPwd:(NSString *)pStr {
    if (!pStr) {
        pStr = userPassword;
    }
    if (!self.pairFeature) return;
    if (!_isConnected)  return;
    self.operaStatus=DevOperaStatus_Login_Start;
    
    
    self.userPassword=pStr;
    uint8_t buffer[17];
    [CryptoAction getRandPro:loginRand Len:8];
    
    buffer[0]=12;
    
    [CryptoAction encryptPair:self.userName
                          Pas:self.userPassword
                        Prand:loginRand
                      PResult:buffer+1];
    
    [self logByte:buffer Len:17 Str:@"Login_String"];
    NSLog(@"[CoreBluetooth] 1.2 写特征值");
    
    kEndTimer(self.loginTimer)
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeWritePairFeatureBack) repeats:NO];
    self.stateCode = BTStateCode_Login;
    [self printContentWithString:[NSString stringWithFormat:@"ready login device with address: 0x%04x", self.selConnectedItem.u_DevAdress]];
    [self writeValue:self.pairFeature Buffer:buffer Len:17 response:CBCharacteristicWriteWithResponse];
}

-(void)SetSelConnectedItem:(BTDevItem *)setTag {
    _selConnectedItem=setTag;
    [self reInitData];
}

-(BTDevItem *)selConnectedItem {
    return _selConnectedItem;
}

-(NSArray *)devArrs {
    return [NSArray arrayWithArray:self.srcDevArrs];
}

-(void)setOperaStatus:(OperaStatus)setTag {
    if (_operaStatus!=setTag) {
        _operaStatus=setTag;
        [self sendDevOperaStatusChange:_operaStatus];
        if (_operaType==DevOperaType_AutoLogin && _operaStatus==DevOperaStatus_Login_Finish) {
            _operaType=DevOperaType_Normal;
        }
        if (_operaType==DevOperaType_Set && _operaStatus==DevOperaStatus_SetNetwork_Finish && (isEndAllSet || !isSetAll)) {
            _operaType=DevOperaType_Normal;
        }
    }
}

-(NSString *)userName{
    if CheckStr(userName)
        self.userName=BTDevInfo_UserNameDef;
    return userName;
}

-(NSString *)userPassword{
    if CheckStr(userPassword)
        self.userPassword=BTDevInfo_UserPasswordDef;
    return userPassword;
}

- (NSArray *)changeCommandToArray:(uint8_t *)cmd len:(int)len {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i=0; i<len; i++) {
        [arr addObject:[NSString stringWithFormat:@"%02X",cmd[i]]];
    }
    return arr;
}

- (void)sendCommand:(uint8_t *)cmd Len:(int)len {
    NSArray *cmdArr = [self changeCommandToArray:cmd len:len];
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970]; //
    if (_clickDate>current) _clickDate = 0;//修复手机修改时间错误造成的命令延时执行错误的问题；
    NSLog(@"[CoreBluetoothh] 执行 ? : %f %@", current,[[self changeCommandToArray:cmd len:len] componentsJoinedByString:@"-"]);
    //if cmd is nil , return;
    if (!cmdArr) return;
    //if _clickDate is equal 0,it means the first time to executor command
    NSTimeInterval count = 0;
    
    if (cmd[7]==0xd0||cmd[7]==0xd2||cmd[7]==0xe2) {
        self.containCYDelay = YES;
        self.btCMDType = BTCommandCaiYang;
        if ((current - _clickDate)<kCMDInterval) {
            if (_clickTimer) {
                dispatch_cancel(_clickTimer);
                //                [_clickTimer invalidate];
                _clickTimer = nil;
                addIndex--;
            }
            //            count = kCMDInterval+self.clickDate-current;
            count = (uint64_t)((kCMDInterval+self.clickDate-current) * NSEC_PER_SEC);
            dispatch_queue_t quen = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _clickTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quen);
            dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(count));
            uint64_t interv = (int64_t)(kCMDInterval * NSEC_PER_SEC);
            dispatch_source_set_timer(_clickTimer, start, interv, 0);
            NSLog(@"执行 ？ 采样: %f %@", current,[[self changeCommandToArray:cmd len:len] componentsJoinedByString:@"-"]);
            dispatch_source_set_event_handler(_clickTimer, ^{
                [self cmdTimer:cmdArr];
            });
            dispatch_resume(_clickTimer);
        }else{
            NSLog(@"执行 ？ 采样直接发出: %f %@", current,[[self changeCommandToArray:cmd len:len] componentsJoinedByString:@"-"]);
            [self cmdTimer:cmdArr];
        }
    }
    else {
        self.btCMDType = BTCommandInterval;
        double temp = current-self.exeCMDDate;
        NSLog(@"执行 ？其他 %@\n", [[self changeCommandToArray:cmd len:len] componentsJoinedByString:@"-"]);
        if (((temp<kCMDInterval)&&(temp>0))||temp<0) {
            if (self.exeCMDDate==0) {
                self.exeCMDDate=current;
            }
            self.exeCMDDate = self.exeCMDDate + kCMDInterval;
            count = self.exeCMDDate + kCMDInterval-current;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(cmdTimer:) withObject:cmdArr afterDelay:count inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, nil]];
            });
        } else {
            [self cmdTimer:cmdArr];
        }
    }
}

- (void)cmdTimer:(id)temp {
    @synchronized (self) {
        if (_clickTimer) {
            dispatch_cancel(_clickTimer);
            //        [_clickTimer invalidate];
            _clickTimer = nil;
            addIndex--;
        }
        int len = (int)[temp count];
        uint8_t cmd[len];
        for (int i = 0; i < len; i++) {
            cmd[i] = strtoul([temp[i] UTF8String], 0, 16);
        }
        NSTimeInterval current = [[NSDate date] timeIntervalSince1970];//
        _clickDate = current;
        [self exeCMD:cmd len:len];
    }
}

- (void)exeCMD:(Byte *)cmd len:(int)len {
    if (!_isConnected ||!_isLogin ||!self.selConnectedItem) return;
    [self printContentWithString:[NSString stringWithFormat:@"execute cmd: %@",[[self changeCommandToArray:cmd len:len] componentsJoinedByString:@" "]]];
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];//
    //保存执行某次命令的时间戳
    NSLog(@"[CoreBluetoothh] 执行 : %f %@", current,[[self changeCommandToArray:cmd len:len] componentsJoinedByString:@"-"]);
    
    if (self.exeCMDDate<current) {
        self.exeCMDDate = current;
    }
    
    uint8_t buffer[20];
    uint8_t sec_ivm[8];
    
    memset(buffer, 0, 20);
    memcpy(buffer, cmd, len);
    memset(sec_ivm, 0,8);
    
    [self getNextSnNo];
    buffer[0]=snNo & 0xff;
    buffer[1]=(snNo>>8) & 0xff;
    buffer[2]=(snNo>>16) & 0xff;
    
    uint32_t tempMac=self.selConnectedItem.u_Mac;
    
    sec_ivm[0]=(tempMac>>24) & 0xff;
    sec_ivm[1]=(tempMac>>16) & 0xff;
    sec_ivm[2]=(tempMac>>8) & 0xff;
    sec_ivm[3]=tempMac & 0xff;
    
    sec_ivm[4]=1;
    sec_ivm[5]=buffer[0];
    sec_ivm[6]=buffer[1];
    sec_ivm[7]=buffer[2];
    [self logByte:buffer Len:20 Str:@"Command"];
    [CryptoAction encryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+3 MicLen:2 Ps:buffer+5 Len:15];
    commentTime = [[NSDate date] timeIntervalSince1970];
    [self writeValue:self.commandFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithoutResponse];
}

+ (BTCentralManager*) shareBTCentralManager {
    static BTCentralManager *shareBTCentralManager = nil;
    static dispatch_once_t tempOnce=0;
    dispatch_once(&tempOnce, ^{
        shareBTCentralManager = [[BTCentralManager alloc] init];
        [shareBTCentralManager initData];
    });
    return shareBTCentralManager;
}

/**
 *一个mesh内部所有灯的all_on
 */

-(void)turnOnAllLight{
    uint8_t cmd[13]={0x11,0x11,0x11,0x00,0x00,0xff,0xff,0xd0,0x11,0x02,0x01,0x01,0x00};
    [self logByte:cmd Len:13 Str:@"All_On"];
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
}

/**
 *一个mesh内部所有灯的all_off
 */
-(void)turnOffAllLight{
    uint8_t cmd[13]={0x11,0x11,0x12,0x00,0x00,0xff,0xff,0xd0,0x11,0x02,0x00,0x01,0x00};
    [self logByte:cmd Len:13 Str:@"All_Off"];
    
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
    
}

/**
 *单灯的开－--------开灯--squrence no＋2
 */
//
-(void)turnOnCertainLightWithAddress:(uint32_t )u_DevAddress{
    uint8_t cmd[13]={0x11,0x71,0x11,0x00,0x00,0x66,0x00,0xd0,0x11,0x02,0x01,0x01,0x00};
    cmd[5]=(u_DevAddress>>8) & 0xff;
    cmd[6]=u_DevAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    
    addIndex++;
    [self logByte:cmd Len:13 Str:@"Turn_On"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
}

/**
 *单灯的关－－－关灯--squrence no＋1
 
 */
-(void)turnOffCertainLightWithAddress:(uint32_t )u_DevAddress{
    uint8_t cmd[13]={0x11,0x11,0x11,0x00,0x00,0x66,0x00,0xd0,0x11,0x02,0x00,0x01,0x00};
    cmd[5]=(u_DevAddress>>8) & 0xff;
    cmd[6]=u_DevAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    
    addIndex++;
    [self logByte:cmd Len:13 Str:@"Turn_Off"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
    
}

/**
 *sendCommand
 
 */
-(void)sendCommand:(NSInteger)opcode meshAddress:(uint32_t)u_DevAddress value:(NSArray *) value{
    uint8_t cmd[10+value.count];
    cmd[0] = 0x11;
    cmd[1] = 0x11;
    cmd[2] = 0x11;
    cmd[3] = 0x00;
    cmd[4] = 0x00;
    cmd[5] = 0x66;
    cmd[6] = 0x00;
    cmd[8] = 0x11;
    cmd[9] = 0x02;
    cmd[5]=u_DevAddress & 0xff;
    cmd[6]=(u_DevAddress>>8) & 0xff;
    cmd[7]=opcode;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    for (int i = 0; i < value.count; i++) {
        cmd[10+i]=[value[i] intValue];
    }
    
    addIndex++;
    [self logByte:cmd Len:10+value.count Str:@"sendCommand"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:10+value.count];
    
}

/**
 *组的开灯－－－传入组地址
 */
-(void)turnOnCertainGroupWithAddress:(uint32_t )u_GroupAddress{
    uint8_t cmd[13]={0x11,0x51,0x11,0x00,0x00,0x66,0x00,0xd0,0x11,0x02,0x01,0x01,0x00};
    cmd[6]=(u_GroupAddress>>8) & 0xff;
    cmd[5]=u_GroupAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    
    addIndex++;
    [self logByte:cmd Len:13 Str:@"Group_On"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
}

/**
 *组的关灯－－－传入组地址
 */
-(void)turnOffCertainGroupWithAddress:(uint32_t )u_GroupAddress{
    uint8_t cmd[13]={0x11,0x31,0x11,0x00,0x00,0x66,0x00,0xd0,0x11,0x02,0x00,0x01,0x00};
    cmd[6]=(u_GroupAddress>>8) & 0xff;
    cmd[5]=u_GroupAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    
    addIndex++;
    [self logByte:cmd Len:13 Str:@"Group_Off"];   //控制台日志
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
}

-(void)replaceDeviceAddress:(uint32_t)presentDevAddress WithNewDevAddress:(NSUInteger)newDevAddress{
    uint8_t cmd[12]={0x11,0x11,0x70,0x00,0x00,0x00,0x00,0xe0,0x11,0x02,0x00,0x00};
    cmd[5]=presentDevAddress & 0xff;
    cmd[6]=(presentDevAddress>>8) & 0xff;
    cmd[10]=newDevAddress & 0xff;
    cmd[11]=(newDevAddress>>8) & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    [self logByte:cmd Len:12 Str:@"Distribute_Address"];   //控制台日志
    [self printContentWithString:[NSString stringWithFormat:@"发出修改地址命令: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    [[BTCentralManager shareBTCentralManager]sendCommand:cmd Len:12];
    
}

/**
 *设置亮度值lum－－传入目的地址和亮度值---可以是单灯或者组的地址
 */
-(void)setLightOrGroupLumWithDestinateAddress:(uint32_t)destinateAddress WithLum:(NSInteger)lum{
    
    uint8_t cmd[11]={0x11,0x11,0x50,0x00,0x00,0x00,0x00,0xd2,0x11,0x02,0x0A};
    cmd[5]=(destinateAddress>>8) & 0xff;
    cmd[6]=destinateAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    //设置亮度值
    cmd[10]=lum;
    //    [self logByte:cmd Len:13 Str:@"Change_Brightness"];
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:11];
}

/**
 *设置RGB－－－传入目的地址和R.G.B值－－-可以是单灯或者组的地址
 */
-(void)setLightOrGroupRGBWithDestinateAddress:(uint32_t)destinateAddress WithColorR:(float)R WithColorG:(float)G WithB:(float)B{
    CGFloat red, green, blue;
    red = (CGFloat)R;
    green = (CGFloat)G;
    blue = (CGFloat)B;
    
    uint8_t cmd[14]={0x11,0x61,0x31,0x00,0x00,0x66,0x00,0xe2,0x11,0x02,0x04,0x0,0x0,0x0};
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    
    
    cmd[5]=destinateAddress & 0xff;
    cmd[6]=(destinateAddress>>8) & 0xff;
    cmd[11]=red*255.f;
    cmd[12]=green*255.f;
    cmd[13]=blue*255.f;
    [self logByte:cmd Len:11 Str:@"RGB"];
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:14];
    
    
}

/**
 *加组－－－传入待加灯的地址，和 待加入的组的地址
 */
-(void)addDevice:(uint32_t)targetDeviceAddress ToDestinateGroupAddress:(uint32_t)groupAddress{
    
    uint8_t cmd[13]={0x11,0x61,0x11,0x00,0x00,0x00,0x00,0xd7,0x11,0x02,0x01,0x02,0x80};
    cmd[5]=(targetDeviceAddress>>8) & 0xff;
    cmd[6]=targetDeviceAddress & 0xff;
    
    cmd[12]=(groupAddress>>8) & 0xff;
    
    cmd[11]=groupAddress & 0xff;
    
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]>=254) {
        cmd[2]=1;
    }
    addIndex++;
    
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
    
}

//删出组
-(void)deleteDevice:(uint32_t)targetDeviceAddress ToDestinateGroupAddress:(uint32_t)groupAddress{
    uint8_t cmd[13]={0x11,0x61,0x11,0x00,0x00,0x00,0x00,0xd7,0x11,0x02,0x00,0x02,0x80};
    cmd[5]=(targetDeviceAddress>>8) & 0xff;
    cmd[6]=targetDeviceAddress & 0xff;
    cmd[12]=(groupAddress>>8) & 0xff;
    cmd[11]=groupAddress & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]>=254) {
        cmd[2]=1;
    }
    addIndex++;
    
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
    
}

/**
 *kick-out---传入待处置的灯的地址－－－地址目前建议只针对组；；；
 目前的功能是,删除灯的所有参数(mac地址除外),并把password、ltk恢 复为出厂值,mesh name设置为“out_of_mesh”
 */
-(void)kickoutLightFromMeshWithDestinateAddress:(uint32_t)destinateAddress {
    uint8_t cmd[11]={0x11,0x61,0x31,0x00,0x00,0x00,0x00,0xe3,0x11,0x02,0x01};
    cmd[5]=(destinateAddress>>8) & 0xff;
    cmd[6]=destinateAddress& 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
//    cmd[10]=0;//0恢复为“out_of_mesh”，1恢复为“telink_mesh1”，默认为1。
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:11];
}

-(void)setCTOfLightWithDestinationAddress:(uint32_t)destinationAddress AndCT:(float)CT{
    uint8_t cmd[12]={0x11,0x11,0x88,0x00,0x00,0x00,0x00,0xe2,0x11,0x02,0x05,0x00};
    cmd[5]=(destinationAddress>>8) & 0xff;
    cmd[6]=destinationAddress & 0xff;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    cmd[11]=CT;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
    
}

- (void)getGroupAddressWithDeviceAddress:(uint32_t)destinationAddress {
    uint8_t cmd[12]={0x11,0x12 ,0x88,0x00,0x00,0x00,0x00,0xdd,0x11,0x02,0x10,0x01};
    cmd[5]=(destinationAddress>>8) & 0xff;
    cmd[6]=destinationAddress & 0xff;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}

///开始OTA前需要先清零Index
- (void)resetOTAPackIndex{
    otaPackIndex = 0;
}

///判断是否可以发送OTA发包(发送非OTA包后，一秒内不可发送OTA包，主要是meshOTA需要)
- (BOOL)canSendPack{
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    BOOL canSend = false;
    if (curTime - commentTime >= 1.0) {
        canSend = true;
    }
    return canSend;
}

/**
 *NewMethod
 */
- (void)sendPack:(NSData *)data {
    if (!_isConnected || !_isLogin ||!self.selConnectedItem || !self.otaFeature ||(self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected))
        return;
    NSUInteger len = data.length;
    if (len > 0 && len < 16) {
        len = 16;
    }
    Byte *tempBytes = (Byte *)[data bytes];
    Byte resultBytes[len + 4];
    memset(resultBytes, 0xff, len + 4);      //初始化
    memcpy(resultBytes+2, tempBytes, data.length); //copy传过来的data
    memcpy(resultBytes, &otaPackIndex, 2); //设置索引
    uint16_t crc = crc16(resultBytes, (int)len+2);
    memcpy(resultBytes+len+2, &crc, 2); //设置crc校验值
    //    NSData *writeData = [NSData dataWithBytes:resultBytes length:len + 4];
    NSData *writeData = [NSData dataWithBytes:resultBytes length:20];
    if (data.length == 0) {
        writeData = [NSData dataWithBytes:resultBytes length:4];
    }
    NSLog(@"otaPackIndex -> %04lx ,length:%lu", (unsigned long)otaPackIndex,(unsigned long)writeData.length);
    [self.selConnectedItem.blDevInfo writeValue:writeData forCharacteristic:self.otaFeature type:CBCharacteristicWriteWithoutResponse];
    otaPackIndex++;
}

extern unsigned short crc16 (unsigned char *pD, int len)
{
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--)
    {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++)
        {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}

/**
 *返回灯的模型－此方法的调用必须调用BTCentralManager的代理方法并且已经扫描登录
 （state－0离线状态-1在线关灯状态-2在线开灯状态）
 */
-(void)readFeatureOfselConnectedItem{
    if (!self.isConnected) {
        return;
    }
    NSLog(@"读取Firmware Revision");
    //读取Firmware Revision
    [self readValue:self.fireWareFeature Buffer:nil];
}


#pragma mark - MeshOTA相关

/**
 读取MeshOTA状态
 */
- (void)readMeshOTAState{
    uint8_t cmd[12]={0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc7,0x11,0x02,0x10,0x05};
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}

/**
 app告诉直连节点进入MeshOTA状态
 @param deviceType 需要MeshOTA的设备类型，如：1、2、3、4
 */
- (void)changeMeshStateToMeshOTAWithDeviceType:(NSInteger )deviceType{
    NSLog(@"%@",[NSString stringWithFormat:@"change Mesh State To MeshOTA With DeviceType %ld",(long)deviceType]);
    uint8_t cmd[15] = {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xc7,0x11,0x02,0x10,0x06,0x01,0x00,0x00};
    cmd[13] = deviceType & 0xff;
    cmd[14] = (deviceType >> 8) & 0xff;
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:15];
}

/**
 读取所有设备版本号
 */
- (void)readFirmwareVersion {
    Byte cmd[12] = {0,0,0,0,0,0xff,0xff,0xc7,0x11,0x02,0x10,0x00};
    NSLog((@"read Firmware Version"));
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}

/**
 meshOTA开始操作，已弃用
 */
- (void)meshOTAStart {
    Byte cmd[12] = {0,0,0,0,0,0,0,0xc6,0x11,0x02,0xff,0xff};
    NSLog(@"meshOTAStart");
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}

/**
 meshOTA停止操作
 */
- (void)meshOTAStop {
    Byte cmd[12] = {0,0,0,0,0,0xff,0xff,0xc6,0x11,0x02,0xfe,0xff};
    NSLog(@"meshOTAStop");
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}


#pragma mark - Other method
-(DeviceModel *)getFristDeviceModelWithBytes:(uint8_t *)bytes{
    DeviceModel *btItem=nil;
    if (bytes[8]==0x11 && bytes[9]==0x02){
        int com=bytes[7];
        int devAd=0;
        
        //状态220
        if (com==0xdc){
            devAd=bytes[10];
            if (devAd == 0) {
                return nil;
            }
            devAd = bytes[10];
            //根据地址得到BTDevItem
            btItem = [self getDeviceWithAddress:devAd];
            if (!btItem) {
                return nil;
            }else{
                //                [self logByte:bytes Len:20 Str:@"First_Status"];
                
                [self logByte:bytes Len:20 Str:@"First_Status"];
                if (bytes[13] == 0) {
                    btItem.reserve = 0;
                    btItem.stata = LightStataTypeOn;
                    btItem.brightness = 0;
                }else{
                    btItem.reserve = 1;
                    btItem.stata = LightStataTypeOn;
                    btItem.brightness = 0;
                }
            }
        }
    }
    
    return  btItem;
}

-(DeviceModel *)getSecondDeviceModelWithBytes:(uint8_t *)bytes{
    DeviceModel *btItem=nil;
    if (bytes[8]==0x11 && bytes[9]==0x02){
        int com=bytes[7];
        int devAd=0;
        //状态220
        if (com==0xdc){
            devAd=bytes[14];
            if (devAd == 0) {
                return nil;
            }
            //            [self logByte:bytes Len:20 Str:@"Second_Status"];
            devAd = bytes[14];
            //根据地址得到BTDevItem
            btItem = [self getDeviceWithAddress:devAd];
            
            if (bytes[13] == 0) {
                btItem.reserve = 0;
                btItem.stata = LightStataTypeOn;
                btItem.brightness = 0;
            }else{
                btItem.reserve = 1;
                btItem.stata = LightStataTypeOn;
                btItem.brightness = 0;
            }
        }
    }
    return  btItem;
}

-(DeviceModel *)getDeviceWithAddress:(uint32_t)address{
    if (address != 0) {
        DeviceModel *devItem = [[DeviceModel alloc]init];
        //类型转换
        uint32_t newAddress = address;
        devItem.u_DevAdress = newAddress;
        
        return devItem;
    }else{
        return nil;
    }
}

//地址更改解析
-(uint32_t)analysisedAddressAfterSettingWithBytes:(uint8_t *)bytes{
    uint32_t result[2];
    [self logByte:bytes Len:20 Str:@"DistributeAddress"];
    result[0] = bytes[10];
    result[1] = bytes[11];
    return *result;
}

- (void)printContentWithString:(NSString *)content {
    //优化：主线程大量调用IO接口写数据到沙盒，会导致APP界面卡顿
    [self performSelector:@selector(printContentOnThreadWithString:) onThread:self.writeLocationThread withObject:content waitUntilDone:NO];
}

- (void)printContentOnThreadWithString:(NSString *)content{
    if (!kTestLog) return;
    NSDate *date = [NSDate date];
    NSDateFormatter *fo = [[NSDateFormatter alloc] init];
    fo.dateFormat = @"HH:mm:ss.SSS";
    fo.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    
    NSString *con = [fo stringFromDate:date];
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"content"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSMutableString *temp = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!temp) {
        temp = [[NSMutableString alloc] init];
    }
    [temp appendFormat:@"%@ %@\n", con, content];
    NSString *cons = [NSString stringWithFormat:@"%@ %@\n", con, content];
    if (self.PrintBlock) {
        self.PrintBlock(cons);
    }
    NSData *dataO = [temp dataUsingEncoding:NSUTF8StringEncoding];
    [dataO writeToFile:path atomically:YES];
}

- (NSString *)currentName {
    return self.userName;
}

- (NSString *)currentPwd {
    return self.userPassword;
}

///设置时间
- (void)setTime {
    BTCentralManager *centralManager = [BTCentralManager shareBTCentralManager];
    if (!centralManager.isLogin){
        return;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponent = [calendar components:unitFlags fromDate:[NSDate date]];
    NSInteger year = [dateComponent year];
    NSInteger month = [dateComponent month];
    NSInteger day = [dateComponent day];
    NSInteger hour = [dateComponent hour];
    NSInteger minute = [dateComponent minute];
    NSInteger second = [dateComponent second];
    
    uint8_t cmd[17]={0x11,0x11,0x5a,0x00,0x00,0xff,0xff,0xe4,0x11,0x02,0xdf,0x07,0x08,0x06,0x09,0x00,0x00};
    cmd[10]=year & 0xff;
    cmd[11]=(year>>8) & 0xff;
    cmd[12]=month & 0xff;
    cmd[13]=day & 0xff;
    cmd[14]=hour & 0xff;
    cmd[15]=minute & 0xff;
    cmd[16]=second & 0xff;
    
    [self logByte:cmd Len:17 Str:@"设置时间"];
    [centralManager sendCommand:cmd Len:17];
}

@end

@implementation BTCentralManager (MeshAdd)

-(void)log:(uint8_t *)bytes Len:(int)len Str:(NSString *)str {
    NSMutableString *tempMStr=[[NSMutableString alloc] init];
    for (int i=0;i<len;i++)
        [tempMStr appendFormat:@"%0x ",bytes[i]];
    NSLog(@"%@ == %@",str,tempMStr);
}

/*
 ALL Default  : 12 11 11 00 00 ff ff c9 11 02 08 ff 00
 DeviceAdrMac : 0c 67 47 00 00 22  00 e0 11 02 30 00 01 10 16 00 00 67 ff ff
 GetDeviceAdrMac : 0c 67 47 00 00 ff  ff e0 11 02 ff ff 01 10
 */
///获取当前mesh网络的所有设备mac
- (void)getAddressMac{
    Byte byte[14] = {0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xe0, 0x11, 0x02, 0xff, 0xff, 0x01, 0x10};
    [self log:byte Len:14 Str:@"getAddressMac"];
    NSLog(@"getAddressMac");
    [self sendCommand:byte Len:14];
}

///修改设备的短地址
- (void)changeDeviceAddress:(uint8_t)address new:(uint8_t)newAddress mac:(uint32_t)mac {
    Byte byte[20] = {0x00, 0x00, 0x00, 0x00, 0x00, address, 0x00, 0xe0, 0x11, 0x02, newAddress, 0x00, 0x01, 0x10, 0,0,0,0,0xff,0xff};
    memcpy(byte + 14, &mac, 4);
    [self log:byte Len:20 Str:@"changeAddressWithMac"];
    [self sendCommand:byte Len:20];
}

///临时设置当前网络到默认网络
- (void)allDefault {
    Byte byte[12] = {0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xc9, 0x11, 0x02, 0x08, 0x2f};
    [self log:byte Len:14 Str:@"allDefault"];
    [self sendCommand:byte Len:12];
}

///清除临时设置
- (void)allResett {
    Byte byte[12] = {0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xc9, 0x11, 0x02, 0x08, 0x00};
    [self log:byte Len:14 Str:@"allResett"];
    [self sendCommand:byte Len:12];
}

@end
