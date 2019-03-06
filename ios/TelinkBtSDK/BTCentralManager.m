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
#define kLoginTimerout (4)

//#define BTLog(A,B) if (_isDebugLog) NSLog(A,B)
#define BTLog(A,B)
static NSUInteger addIndex;
static NSUInteger scanTime;
static NSUInteger getNotifytime;

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
@property (nonatomic, strong)NSMutableArray *IdentifersArrs;
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
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey:@NO}];
    self.srcDevArrs=[[NSMutableArray alloc] init];
    self.IdentifersArrs = [[NSMutableArray alloc]init];
    self.isNeedScan=NO;
    _isConnected=NO;
    _centerState=CBCentralManagerStateUnknown;
    _operaType=DevOperaType_Normal;
    self.currSetIndex=NSNotFound;
    memset(sectionKey, 0, 16);
    srand((int)time(0));
    self.snNo=random(MaxSnValue);
    self.isDebugLog=NO;
//    _duration = 300;
    otaPackIndex = 0;
    memset(tempbuffer, 0, 20);

    //开启延迟线程
    _delayThread = [[NSThread alloc] initWithTarget:self selector:@selector(startThread) object:nil];
    [_delayThread start];
}

-(void)startThread {
    [self performSelector:@selector(_) withObject:nil afterDelay:[[NSDate distantFuture] timeIntervalSince1970]];
    [NSThread currentThread].name = @"Delay Thread";

    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {

    }

}

-(void)_{}

#pragma mark - Private

//初始化连接状态
-(void)reInitData
{
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

-(int)getNextSnNo {
    snNo++;
    if (snNo>MaxSnValue)
        snNo=1;
    return self.snNo;
}

-(uint32_t)getIntValueByHex:(NSString *)getStr
{
    NSScanner *tempScaner=[[NSScanner alloc] initWithString:getStr];
    uint32_t tempValue;
    [tempScaner scanHexInt:&tempValue];
    return tempValue;
}
-(BTDevItem *)getItemWithTag:(NSString *)getStr
{
    BTDevItem *result=nil;
    for (BTDevItem *tempItem in srcDevArrs)
    {
        if ([tempItem.devIdentifier isEqualToString:getStr])
        {
            result=tempItem;
            break;
        }
    }
    return result;
}

-(BTDevItem *)getDevItemWithPer:(CBPeripheral *)getPer
{
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

//-(void)writeValue:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer Len:(int)len
//{
//    if (!characteristic)
//        return;
//
//    if (!self.selConnectedItem)
//        return;
//
//    if (self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected)
//        return;
//
//    NSData *tempData=[NSData dataWithBytes:buffer length:len];
//
//    [self.selConnectedItem.blDevInfo writeValue:tempData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//
//}

-(void)readValue:(CBCharacteristic *)characteristic Buffer:(uint8_t *)buffer
{
    if (!characteristic)
        return;

    if (!self.selConnectedItem)
        return;

    if (self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected)
        return;

    [self.selConnectedItem.blDevInfo readValueForCharacteristic:characteristic];
}


-(void)logByte:(uint8_t *)bytes Len:(int)len Str:(NSString *)str
{
    NSMutableString *tempMStr=[[NSMutableString alloc] init];
    for (int i=0;i<len;i++)
        [tempMStr appendFormat:@"%0x ",bytes[i]];
}

-(void)pasterData:(uint8_t *)buffer IsNotify:(BOOL)isNotify
{

    uint8_t sec_ivm[8];
    uint32_t tempMac=self.selConnectedItem.u_Mac;

    sec_ivm[0]=(tempMac>>24) & 0xff;
    sec_ivm[1]=(tempMac>>16) & 0xff;
    sec_ivm[2]=(tempMac>>8) & 0xff;

    memcpy(sec_ivm+3, buffer, 5);

    if (!(buffer[0]==0 && buffer[1]==0 && buffer[2]==0))
    {
        if ([CryptoAction decryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+5 MicLen:2 Ps:buffer+7 Len:13]){
            //NSLog(@"解密返回成功");
        }else{
            //NSLog(@"解密返回失败");
        }
    }
    if (isNotify)
        [self sendDevNotify:buffer];
    else
        [self sendDevCommandReport:buffer];
}

-(BTDevItem *)getNextItemWith:(BTDevItem *)getItem
{
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
-(void)sendCenterStatusChange
{
    if (_delegate && [_delegate respondsToSelector:@selector(OnCenterStatusChange:)])
    {
        [_delegate OnCenterStatusChange:self];
    }
}

-(void)sendDevChange:(BTDevItem *)item Flag:(DevChangeFlag)flag
{
    if (_delegate && [_delegate respondsToSelector:@selector(OnDevChange:Item:Flag:)])
    {
        [_delegate OnDevChange:self Item:item Flag:flag];
    }
}

-(void)sendDevNotify:(uint8_t *)bytes
{
    [self logByte:bytes Len:20 Str:@"Notify"];

    if (_delegate && [_delegate respondsToSelector:@selector(OnDevNofify:Byte:)])
    {
        [_delegate OnDevNofify:self Byte:bytes];
    }
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
            year = (year1 << 8) + year2;
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
-(void)setNewNetworkDataPro{
    NSLog(@"[CoreBluetooth] ready set new mesh");
    [self printContentWithString:[NSString stringWithFormat:@"ready set new mesh: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];

    uint8_t buffer[20];
    memset(buffer, 0, 20);

    self.operaStatus=DevOperaStatus_SetName_Start;
    [CryptoAction  getNetworkInfo:buffer Opcode:4 Str:self.nUserName Psk:sectionKey];
//    [self writeValue:self.pairFeature Buffer:buffer Len:20];
     [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    //NSLog(@"Setting_Name");

    self.operaStatus=DevOperaStatus_SetPassword_Start;
    memset(buffer, 0, 20);
    [CryptoAction  getNetworkInfo:buffer Opcode:5 Str:self.nUserPassword Psk:sectionKey];
     [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
//    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    //NSLog(@"Seting_Password");

    self.operaStatus=DevOperaStatus_SetLtk_Start;
    [CryptoAction  getNetworkInfoByte:buffer Opcode:6 Str:tempbuffer Psk:sectionKey];
//    [self writeValue:self.pairFeature Buffer:buffer Len:20];
    [self writeValue:self.pairFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithResponse];
    //NSLog(@"Setting_Ltk");
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

-(void)setOut_Of_MeshWithName:(NSString *)addName PassWord:(NSString *)addPassWord NewNetWorkName:(NSString *)nName Pwd:(NSString *)nPwd ltkBuffer:(uint8_t *)buffer ForCertainItem:(BTDevItem *)item{
    if (!item) {
        return;
    }
    self.isSetAll = NO;
    self.nUserName=nName;
    self.nUserPassword=nPwd;                      //加灯时候的passwordnUserPassword
    self.userName = addName;
    self.userPassword = addPassWord;
    if (![_selConnectedItem isEqual:item]) {
        NSLog(@"[CoreBluetooth] 认领失败u_DevAdress = %d",item.u_DevAdress);
        [self stopConnected];
    }
    _operaType = DevOperaType_Set;

    if (buffer != nil) {
        for (int i = 0;  i < 20 ; i++) {
            tempbuffer[i] = buffer[i];
        }
    }
    [self printContentWithString:[NSString stringWithFormat:@"change mesh name and set ltk: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    [self setNewNetworkWithItem:item];
}




-(void)setNewNetworkName:(NSString *)nName Pwd:(NSString *)nPwd WithItem:(BTDevItem *)item ltkBuffer:(uint8_t *)buffer
{
    NSLog(@"item==========%@",item);
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
    [self setNewNetworkWithItem:item];
    if (buffer != nil) {
        for (int i = 0;  i < 20 ; i++) {
            tempbuffer[i] = buffer[i];
        }
    }
    [self printContentWithString:[NSString stringWithFormat:@"change mesh name and ltk: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
}
-(void)setNewNetworkNextPro
{
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
    [self.centralManager connectPeripheral:[setItem blDevInfo]
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnConnectionKey]];
    NSLog(@"[CoreBluetooth] setMeshNameAndPwdAndLtk: -> %@", [setItem blDevInfo]);
}

-(void)setNewNetworkWithItem:(BTDevItem *)setItem{
    _selConnectedItem=setItem;
    self.flags = YES;
    setItem.isSeted=YES;

    for (int i=0; i<srcDevArrs.count; i++) {
        if ([srcDevArrs[i] u_Mac] == setItem.u_Mac) {
            [srcDevArrs replaceObjectAtIndex:i withObject:setItem];
        }
        NSLog(@"[CoreBluetooth] srcDevArrs -> %@", [srcDevArrs[i] blDevInfo]);
    }
    [self.centralManager connectPeripheral:[setItem blDevInfo]
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    NSLog(@"[CoreBluetooth] setNewNetworkWithItem: -> %@", [setItem blDevInfo]);
}


-(void)stopConnected{
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
    if (getNotifytime < 4) {
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
    //NSLog(@"获取灯的状态");
    uint8_t buffer[1]={1};
    [self writeValue:self.notifyFeature Buffer:buffer Len:1 response:CBCharacteristicWriteWithResponse];
}

#pragma mark - BlueDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    _centerState=central.state;
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        if (isNeedScan)
            [self startScanWithName:self.userName Pwd:self.userPassword];
    }else if (central.state==CBCentralManagerStatePoweredOff){
        [self stopConnected];
        [self stopScan];
    }
    [self sendCenterStatusChange];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSString *tempUserName=[advertisementData objectForKey:@"kCBAdvDataLocalName"]; //广播包名字LocalName
    BOOL scanContainOut_of_mesh = self.scanWithOut_Of_Mesh;
    BOOL scanOption1 = [tempUserName isEqualToString:self.userName];
    BOOL scanOption2 = [tempUserName isEqualToString:@"out_of_mesh"];
    BOOL options;
//    options = scanContainOut_of_mesh ? (scanOption1 || scanOption2) : scanOption1;
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
    NSLog(@"advertisementData -> %@", advertisementData);
    [self printContentWithString:[NSString stringWithFormat:@"kCBAdvDataManufacturerData :  %@",advertisementData[@"kCBAdvDataManufacturerData"]]];
    if (tempParStr.length>=30){
        //Uid
        NSRange tempRange=NSMakeRange(1, 4);
        NSString *tempStr=[tempParStr substringWithRange:tempRange];
        uint32_t tempVid=[self getIntValueByHex:tempStr];
        if (tempVid==BTDevInfo_UID) {
            NSString *tempUuid=[[peripheral identifier] UUIDString];
            [self.IdentifersArrs addObject:peripheral];
            BTDevItem *tempItem=[self getItemWithTag:tempUuid];
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
                //ios9--<11021102 2211ffff 11022211 ffff0500 010f0000 01020304 05060708 090a0b0c 0d0e0f>
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
    //[self.centralManager stopScan];
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
    if (self.loginTimer) {
        [self.loginTimer invalidate];
        self.loginTimer = nil;
    }
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeScanServices) repeats:NO];
    [peripheral discoverServices:nil];
}
- (void)loginT:(NSTimer *)timer {
    NSLog(@"[CoreBluetooth] 超时  -> %ld", (TimeoutType)[timer.userInfo intValue]);
    if ([self.delegate respondsToSelector:@selector(loginTimeout:)]) {
        [self.delegate loginTimeout:(TimeoutType)[timer.userInfo intValue]];
    }

    if (self.loginTimer) {
        [self.loginTimer invalidate];
        self.loginTimer = nil;
    }
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"[CoreBluetooth] 0.7.2 连接设备失败的回调 %@ %d", error, error.code);

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

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    BTDevItem *item = [self getDevItemWithPer:peripheral];
    [self printContentWithString:[NSString stringWithFormat:@"did disconnect address: 0x%04x", item.u_DevAdress]];
    NSLog(@"[CoreBluetooth] 0.7.2 设备断开连接");
    //对断开连接的灯进行设置
    if ([_delegate respondsToSelector:@selector(scanResult:)]) {
        [[BTCentralManager shareBTCentralManager]connectWithItem:item];
        [_delegate scanResult:item];
    }
    if ([_delegate respondsToSelector:@selector(settingForDisconnect:WithDisconectType:)]) {
        [_delegate settingForDisconnect:item WithDisconectType:DisconectType_SequrenceSetting];

    }
    if ([_delegate respondsToSelector:@selector(loginout:)]) {
        [_delegate loginout:item];
    }
    self.disconnectType = DisconectType_Normal;
    [self reInitData];

    if (_operaType==DevOperaType_Set){
        [self selConnectedItem];
        if (self.flags == YES) {
            self.flags = NO;
        }else{
            NSLog(@"[CoreBluetooth] 从设备断开连接的回调调用连接设备的方法");
            [self connectPro];
            NSLog(@"[CoreBluetooth] 从设备断开连接的回调调用连接设备的方法结束");
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
//    BTLog(@"%@",@"Disconnect");
//    [self reInitData];
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

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
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

            if (self.loginTimer) {
                [self.loginTimer invalidate];
                self.loginTimer = nil;
            }
            self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeScanCharacteritics) repeats:NO];
        }
        if ([tempSer.UUID isEqual:[CBUUID UUIDWithString:Service_Device_Information]]) {
            [peripheral discoverCharacteristics:nil forService:tempSer];

        }
//        if ([tempSer.UUID isEqual:[CBUUID UUIDWithString:Service_Device_Information]]) {
//            [peripheral discoverCharacteristics:nil forService:tempSer];
//        }
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
            if ([self.delegate respondsToSelector:@selector(scanedLoginCharacteristic)]) {
                [self.delegate scanedLoginCharacteristic];
            }
            if (_operaType == DevOperaType_Set || _operaType == DevOperaType_AutoLogin){
                NSLog(@"[CoreBluetooth] 1.0 调用登录");
                [self loginWithPwd:self.userPassword];      //    self.userName = addName;//扫描
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
                    if ([_delegate respondsToSelector:@selector(OnDevChange:Item:Flag:)]) {
                        [_delegate OnDevChange:self Item:[self getDevItemWithPer:peripheral] Flag:DevChangeFlag_Login];
                    }
                    if (!self.scanWithOut_Of_Mesh) {
                        [self.getNotifyTimer invalidate];
                        self.getNotifyTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(setNotifyOpenProSevervalTimes) userInfo:nil repeats:YES];
                    }
                }
            }
            if (!_isLogin) {
                if (self.loginTimer) {
                    [self.loginTimer invalidate];
                    self.loginTimer = nil;
                }
                [self printContentWithString:[NSString stringWithFormat:@"login fail with address: 0x%04x", self.selConnectedItem.u_DevAdress]];
                [self stopConnected];//重置BUG
            }else{
                if (self.loginTimer) {
                    [self.loginTimer invalidate];
                    self.loginTimer = nil;
                }
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
            }
            if (isSetAll && !self.isEndAllSet)
                [self setNewNetworkNextPro];
            else{
                self.operaStatus=DevOperaStatus_SetNetwork_Finish;
                NSLog(@"[CoreBluetooth] SetNetwork_Finish");
            }

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
        if ([_delegate respondsToSelector:@selector(OnConnectionDevFirmWare:)] && tempData) {
            [_delegate OnConnectionDevFirmWare:tempData];
        }
        if ([_delegate respondsToSelector:@selector(OnConnectionDevFirmWare:Item:)]) {
            BTDevItem *item= [self getDevItemWithPer:peripheral];
            [_delegate OnConnectionDevFirmWare:tempData Item:item];
        }
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error && ![characteristic isEqual:self.otaFeature]) {
        //NSLog(@"Write___Error: %@<--> %@", [error localizedFailureReason],[[NSString alloc]initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
        return;
    }
    BTLog(@"%@",@"Write Successed");
    if ([characteristic isEqual:self.pairFeature]){
        [self.selConnectedItem.blDevInfo readValueForCharacteristic:self.pairFeature];
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
    _operaType = DevOperaType_Normal;
    //if (_centerState == CBCentralManagerStatePoweredOn) {
        [self printContentWithString:@"ready scan devices "];
        [_centralManager scanForPeripheralsWithServices:nil options:nil];
    //}
    //如果是最后一个设备被断电的时候
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
        [self reInitData];
        [_centralManager stopScan];
    }
}

-(void)connectPro
{

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


    [self.centralManager connectPeripheral:[item blDevInfo]
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    NSString *tip = [NSString stringWithFormat:@"send connect request for address: 0x%04x", self.selConnectedItem.u_DevAdress];
    [self printContentWithString:tip];

    if (self.loginTimer) {
        [self.loginTimer invalidate];
        self.loginTimer = nil;
    }
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeConnectting) repeats:NO];
}

-(void)connectNextPro
{
    if ([srcDevArrs count]<2)
        return;

    BTDevItem *tempItem=[self getNextItemWith:self.selConnectedItem];
    if (!tempItem)
        return;
    [self printContentWithString:[NSString stringWithFormat:@"connect next device : 0x%04x", tempItem.u_DevAdress]];
    _selConnectedItem=tempItem;
    [self.centralManager connectPeripheral:[tempItem blDevInfo]
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

-(void)connectWithItem:(BTDevItem *)cItem
{
    [self stopConnected];
    if (!cItem)
        return;
    [self printContentWithString:[NSString stringWithFormat:@"connect device directly : 0x%04x", cItem.u_DevAdress]];
    _selConnectedItem=cItem;
    [self.centralManager connectPeripheral:[cItem blDevInfo]
                                   options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];

}

-(void)loginWithPwd:(NSString *)pStr {
    if (!pStr) {
        pStr = userPassword;
    }
    if (!self.pairFeature) {
        return;
    }
    //NSLog(@"Logining");
    self.operaStatus=DevOperaStatus_Login_Start;
    if (!_isConnected)
        return;

    self.userPassword=pStr;
    uint8_t buffer[17];
    [CryptoAction getRandPro:loginRand Len:8];

    for (int i=0;i<8;i++)
        loginRand[i]=i;

    buffer[0]=12;

    [CryptoAction encryptPair:self.userName
                          Pas:self.userPassword
                        Prand:loginRand
                      PResult:buffer+1];

    [self logByte:buffer Len:17 Str:@"Login_String"];
//    [self writeValue:self.pairFeature Buffer:buffer Len:17];
    NSLog(@"[CoreBluetooth] 1.2 写特征值");
    if (self.loginTimer) {
        [self.loginTimer invalidate];
        self.loginTimer = nil;
    }
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:kLoginTimerout target:self selector:@selector(loginT:) userInfo:@(TimeoutTypeWritePairFeatureBack) repeats:NO];
    if (self.pairFeature) {
        [self printContentWithString:[NSString stringWithFormat:@"ready login device with address: 0x%04x", self.selConnectedItem.u_DevAdress]];
        [self writeValue:self.pairFeature Buffer:buffer Len:17 response:CBCharacteristicWriteWithResponse];
    }
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

-(NSString *)userName
{
    if CheckStr(userName)
        self.userName=BTDevInfo_UserNameDef;
    return userName;
}

-(NSString *)userPassword
{
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
    [self printContentWithString:[NSString stringWithFormat:@"   ready cmd: %@",[cmdArr componentsJoinedByString:@" "]]];
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
                [self performSelector:@selector(cmdTimer:) withObject:cmdArr afterDelay:count];
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
    [self logByte:cmd Len:len Str:@"Command_String"];
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

    [CryptoAction encryptionPpacket:sectionKey Iv:sec_ivm Mic:buffer+3 MicLen:2 Ps:buffer+5 Len:15];

    [self logByte:buffer Len:20 Str:@"加密结果"];
    [self writeValue:self.commandFeature Buffer:buffer Len:20 response:CBCharacteristicWriteWithoutResponse];

}

+ (BTCentralManager*) shareBTCentralManager
{

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
    uint8_t cmd[13]={0x11,0x71,0x11,0x00,0x00,0x66,0x00,0xf0,0x11,0x02,0x01,0x01,0x00};
    cmd[5]=u_DevAddress & 0xff;
    cmd[6]=(u_DevAddress>>8) & 0xff;
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
    uint8_t cmd[13]={0x11,0x11,0x11,0x00,0x00,0x66,0x00,0xf0,0x11,0x02,0x00,0x01,0x00};
    cmd[5]=u_DevAddress & 0xff;
    cmd[6]=(u_DevAddress>>8) & 0xff;
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

/**
 *组的开灯－－－传入组地址
 */
-(void)turnOnCertainGroupWithAddress:(uint32_t )u_GroupAddress
{
    uint8_t cmd[13]={0x11,0x51,0x11,0x00,0x00,0x66,0x00,0xf0,0x11,0x02,0x01,0x01,0x00};
    cmd[5]=u_GroupAddress & 0xff;
    cmd[6]=(u_GroupAddress>>8) & 0xff;
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
-(void)turnOffCertainGroupWithAddress:(uint32_t )u_GroupAddress
{
    uint8_t cmd[13]={0x11,0x31,0x11,0x00,0x00,0x66,0x00,0xd0,0x11,0x02,0x00,0x01,0x00};
    cmd[5]=u_GroupAddress & 0xff;
    cmd[6]=(u_GroupAddress>>8) & 0xff;
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
    [self logByte:cmd Len:13 Str:@"Distribute_Address"];   //控制台日志
    [self printContentWithString:[NSString stringWithFormat:@"发出修改地址命令: 0x%04x", [[srcDevArrs firstObject] u_DevAdress]]];
    [[BTCentralManager shareBTCentralManager]sendCommand:cmd Len:12];

}


/**
 *设置亮度值lum－－传入目的地址和亮度值---可以是单灯或者组的地址
 */
-(void)setLightOrGroupLumWithDestinateAddress:(uint32_t)destinateAddress WithLum:(NSInteger)lum{

    uint8_t cmd[11]={0x11,0x11,0x50,0x00,0x00,0x00,0x00,0xd2,0x11,0x02,0x0A};
    cmd[5]=destinateAddress & 0xff;
    cmd[6]=(destinateAddress>>8) & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    //设置亮度值
    cmd[10]=lum;
    [self logByte:cmd Len:13 Str:@"Change_Brightness"];
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];
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
    cmd[5]=targetDeviceAddress & 0xff;
    cmd[6]=(targetDeviceAddress>>8) & 0xff;

    cmd[11]=groupAddress & 0xff;
    cmd[12]=(groupAddress>>8) & 0xff;

    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]>=254) {
        cmd[2]=1;
    }
    addIndex++;

    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:13];

}

//删出组
-(void)deleteDevice:(uint32_t)targetDeviceAddress ToDestinateGroupAddress:(uint32_t)groupAddress
{
    uint8_t cmd[13]={0x11,0x61,0x11,0x00,0x00,0x00,0x00,0xd7,0x11,0x02,0x00,0x02,0x80};
    cmd[5]=targetDeviceAddress & 0xff;
    cmd[6]=(targetDeviceAddress>>8) & 0xff;
    cmd[11]=groupAddress & 0xff;
    cmd[12]=(groupAddress>>8) & 0xff;
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
    uint8_t cmd[10]={0x11,0x61,0x31,0x00,0x00,0x00,0x00,0xe3,0x11,0x02,};
    cmd[5]=destinateAddress& 0xff;
    cmd[6]=(destinateAddress>>8) & 0xff;
    cmd[2]=cmd[2]+addIndex;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:10];
}

-(void)setCTOfLightWithDestinationAddress:(uint32_t)destinationAddress AndCT:(float)CT{
    uint8_t cmd[12]={0x11,0x11,0x88,0x00,0x00,0x00,0x00,0xe2,0x11,0x02,0x05,0x00};
    cmd[5]=destinationAddress & 0xff;
    cmd[6]=(destinationAddress>>8) & 0xff;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    cmd[10]=CT;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];

}
- (void)getGroupAddressWithDeviceAddress:(uint32_t)destinationAddress {
    uint8_t cmd[12]={0x11,0x12 ,0x88,0x00,0x00,0x00,0x00,0xdd,0x11,0x02,0x10,0x01};
    cmd[5]=destinationAddress & 0xff;
    cmd[6]=(destinationAddress>>8) & 0xff;
    if (cmd[2]==254) {
        cmd[2]=1;
    }
    addIndex++;
    [[BTCentralManager shareBTCentralManager] sendCommand:cmd Len:12];
}
/**
 *NewMethod


 */
-(void)sendPack:(NSData *)data{
    if (!_isConnected || !_isLogin ||!self.selConnectedItem || !self.otaFeature ||(self.selConnectedItem.blDevInfo.state!=CBPeripheralStateConnected))
        return;

    NSUInteger length = data.length;
    uint8_t *tempData=(uint8_t *)[data bytes];                 //数据包
    uint8_t pack_head[2];
    pack_head[1] = (otaPackIndex >>8)& 0xff;                    //从0开始
    pack_head[0] = (otaPackIndex)&0xff;

    //普通数据包
    if (length > 0 && length < 16) {
        length = 16;
    }
    uint8_t otaBuffer[length+4];              //总包
    memset(otaBuffer, 0, length+4);


    uint8_t otaCmd[length+2];               //待校验包
    memset(otaCmd, 0, length+2);

    for (int i = 0; i < 2; i ++) {                    //index指数部分
        otaBuffer[i] = pack_head[i];
    }
    for (int i = 2; i < length+2; i++) {        //bin 文件数据包
        if (i < [data length]+2) {
            otaBuffer[i] = tempData[i-2];
        }else{
            otaBuffer[i] = 0xff;
        }
    }
    for (int i = 0; i < length+2; i++) {
        otaCmd[i] = otaBuffer[i];
    }

    //CRC校验部分
    unsigned short crc_t = crc16(otaCmd, (int)length+2);
    uint8_t crc[2];
    crc[1] = (crc_t >> 8) & 0xff;
    crc[0] = (crc_t)&0xff;
    for (int i = (int)length+3; i > (int)length+1; i--) {   //2->4
        otaBuffer[i] = crc[i-length-2];
    }

    [self logByte:otaBuffer Len:(int)length+4 Str:@"数据包"];
    NSData *tempdata=[NSData dataWithBytes:otaBuffer length:length+4];
    if (self.isLogin) {
        [self.selConnectedItem.blDevInfo writeValue:tempdata forCharacteristic:self.otaFeature type:CBCharacteristicWriteWithoutResponse];
    }
    else{
        [self.selConnectedItem.blDevInfo writeValue:tempdata forCharacteristic:self.otaFeature type:CBCharacteristicWriteWithResponse];
    }

    otaPackIndex++;
    if (!self.isConnected || !self.isLogin || length == 0) {
        otaPackIndex = NSNotFound;
    }
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
    //读取Firmware Revision
    [self readValue:self.fireWareFeature Buffer:nil];
}

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
//                if (bytes[11] == 0) {
//                    btItem.stata = LightStataTypeOutline;
//                    btItem.brightness = 0;
//                }else{
//                    btItem.brightness = bytes[12];
//                    if (bytes[12] == 0) {
//                        btItem.stata = LightStataTypeOff;
//                    }else{
//                        btItem.stata = LightStataTypeOn;
//                    }
//
//                }
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
            [self logByte:bytes Len:20 Str:@"Second_Status"];
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

//            if (bytes[15] == 0) {
//                btItem.stata = LightStataTypeOutline;
//                btItem.brightness = 0;
//            }else{
//                btItem.brightness = bytes[16];
//                if (bytes[16] == 0) {
//                    btItem.stata = LightStataTypeOff;
//                }else{
//                    btItem.stata = LightStataTypeOn;
//                }
//            }
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
    if (!kTestLog) return;
    NSDate *date = [NSDate date];
    NSDateFormatter *fo = [[NSDateFormatter alloc] init];
    fo.dateFormat = @"HH:mm:ss";
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
@end
