/********************************************************************************************************
 * @file     MeshOTAVC.m
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
//  MeshOTAVC.m
//  TelinkBlueDemo
//
//  Created by Arvin on 2018/4/17.
//  Copyright © 2018年 Green. All rights reserved.
//

#import "MeshOTAVC.h"
#import "MeshOTAItemCell.h"
#import "MeshOTAItemModel.h"
#import "UIButton+extension.h"
#import "UIAlertView+Extension.h"
#import "SysSetting.h"
#import "BTCentralManager.h"
#import "DemoDefine.h"
#import "MeshOTAManager.h"

@interface MeshOTAVC ()<UITableViewDataSource,UITableViewDelegate,BTCentralManagerDelegate>{
    BTCentralManager *centraManager;
}
@property (weak, nonatomic) IBOutlet UIButton *firmwareButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) NSMutableArray *binStringArray;
@property (nonatomic, strong) NSMutableArray *binDataArray;
@property (nonatomic, assign) NSInteger itemIndex;
@property (nonatomic, assign) NSInteger binIndex;

@end


/**
 MeshOTA注意事项：
 1.开始MeshOTA接口startMeshOTAWithDeviceType需要传入设备的类型和需要升级的OTA文件，通过普通模式添加的设备可以在添加过程中获取到设备类型，通过Mesh模式添加的设备，当前是没有获取到设备类型的。
 2. meshOTA模式流程可以参考文档mesh_ota_Flow.docx

 */
@implementation MeshOTAVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"Mesh OTA";
    
    //去掉多余的分割线
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footerView;
    //注册cell
    [self.tableView registerNib:[UINib nibWithNibName:@"MeshOTAItemCell" bundle:nil] forCellReuseIdentifier:@"MeshOTAItemCell"];
    
    //设置默认勾选
    self.itemIndex = -1;
    self.binIndex = -1;

    [self configMeshOTAList];
    
    [self getAllBinFile];
    
    //非本手机添加的蓝牙设备，手机本地不存在设备的类型、mac、版本号，需重新获取一次。
    centraManager = [BTCentralManager shareBTCentralManager];
    [centraManager readFirmwareVersion];
    [centraManager getAddressMac];

    [self performSelector:@selector(reloadType) withObject:nil afterDelay:2.0];

    if ([MeshOTAManager share].isMeshOTAing) {
        [self userAbled:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void)reloadType{
    [self configMeshOTAList];
    [self.tableView reloadData];
}

- (void)configMeshOTAList{
    self.array = [[NSMutableArray alloc] init];
    //获取本地所有设备类型
    NSArray *dataArray = [[MeshOTAManager share] getAllDevices];
    NSMutableArray *pids = [NSMutableArray array];
    for (DeviceModel *device in dataArray) {
        NSNumber *temPid = [SysSetting getProductuuidWithDeviceAddress:device.u_DevAdress >> 8];
        if (![temPid isEqualToNumber:@(0)] && ![pids containsObject:temPid]) {
            [pids addObject:temPid];
        }
    }
    //判断每个设备类型是否可以OTA
    for (NSNumber *pid in pids) {
        MeshOTAItemModel *item = [[MeshOTAItemModel alloc] init];
        item.deviceType = pid.integerValue;
        item.OTAAble = NO;
        for (DeviceModel *device in dataArray) {
            if ([[SysSetting getProductuuidWithDeviceAddress:device.u_DevAdress >> 8] isEqualToNumber:pid] && device.stata != LightStataTypeOutline) {
                item.OTAAble = YES;
                break;
            }
        }
        [self.array addObject:item];
    }
}

- (NSNumber *)getProductuuidWithDeviceAddress:(NSInteger )address{
    NSArray *dataArray = [[SysSetting shareSetting] currentLocalDevicesDict];
    for (NSDictionary *dict in dataArray) {
        NSNumber *temAdd = (NSNumber *)dict[Address];
        if ([temAdd isEqualToNumber:@(address)]) {
            return (NSNumber *)dict[Productuuid];
        }
    }
    return @(0);
}

- (void)getAllBinFile{
    self.binStringArray = [NSMutableArray array];
    self.binDataArray = [NSMutableArray array];
    
    // 搜索bin文件的目录
    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"bin" inDirectory:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *binPath in paths) {
        NSData *binData = [fileManager contentsAtPath:binPath];
        [self.binDataArray addObject:binData];
        NSString *binName = [fileManager displayNameAtPath:binPath];
        [self.binStringArray addObject:binName];
    }
    
    //搜索Documents(通过iTunes File 加入的文件需要在此搜索)
    NSFileManager *mang = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *fileLocalPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSArray *fileNames = [mang contentsOfDirectoryAtPath:fileLocalPath error:&error];
    for (NSString *path in fileNames) {
        if ([path containsString:@".bin"]) {
            [self.binStringArray addObject:path];
                //通过iTunes File 加入的文件
                NSString *fileLocalPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                fileLocalPath = [NSString stringWithFormat:@"%@/%@",fileLocalPath,path];
                NSError *err = nil;
                NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:[NSURL URLWithString:fileLocalPath] error:&err];
               NSData *data = fileHandle.readDataToEndOfFile;
            [self.binDataArray addObject:data];

        }
    }
}

- (void)setStartButtonEnable:(BOOL)enable{
    self.startButton.backgroundColor = enable ? [UIColor colorWithRed:66/255.0 green:193/255.0 blue:247/255.0 alpha:1.0] : [UIColor colorWithRed:66/255.0 green:193/255.0 blue:247/255.0 alpha:0.5];
}

- (IBAction)clickGetAllFirmware:(UIButton *)sender {
    if (![MeshOTAManager share].isMeshOTAing) {
        [centraManager readFirmwareVersion];
        [self performSelector:@selector(reloadType) withObject:nil afterDelay:1.5];
    }else{
        [UIAlertView alertWithMessage:@"在meshOTA中，不可查询firmware"];
    }
}

- (IBAction)clickStartMeshOTA:(UIButton *)sender {
    if (![MeshOTAManager share].isMeshOTAing) {
        [self startMeshOTA];
    }else{
        [UIAlertView alertWithMessage:@"已经在meshOTA中，不可重复进行"];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return section == 0 ? self.array.count : self.binStringArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(MeshOTAItemCell.class) forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    MeshOTAItemCell *itemCell = (MeshOTAItemCell *)cell;
    __weak typeof(self) weakSelf = self;
    
    if (indexPath.section == 0) {
        MeshOTAItemModel *item = self.array[indexPath.row];
        itemCell.titleLabel.text = [NSString stringWithFormat:@"%ld",(long)item.deviceType];
        if (item.deviceType == 1) {
            itemCell.titleLabel.text = @"1-Life";
        }else if (item.deviceType == 5){
            itemCell.titleLabel.text = @"5-Sleep";
        }
        itemCell.selectButton.selected = indexPath.row == _itemIndex;
        [itemCell.selectButton addAction:^(UIButton *button) {
            weakSelf.itemIndex = indexPath.row;
            [weakSelf.tableView reloadData];
        }];
    } else {
        NSString *binString = self.binStringArray[indexPath.row];
        itemCell.titleLabel.text = binString;
        itemCell.selectButton.selected = indexPath.row == _binIndex;
        [itemCell.selectButton addAction:^(UIButton *button) {
            weakSelf.binIndex = indexPath.row;
            [weakSelf.tableView reloadData];
        }];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Device type";
    } else {
        return @"OTA file";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        MeshOTAItemModel *item = self.array[indexPath.row];
        if (item.OTAAble) {
            //可以OTA
            _itemIndex = indexPath.row;
        } else {
            //不可以OTA
            [UIAlertView alertWithMessage:@"没有可升级的该类型设备"];
        }
    } else {
        _binIndex = indexPath.row;
    }
    [self.tableView reloadData];
}

/*
 1.查询meshOTA状态
 2.进入mesh OTA状态
 */
- (void)startMeshOTA{
    if (self.itemIndex < 0) {
        [UIAlertView alertWithMessage:@"请选择OTA的设备类型"];
        return;
    }
    if (self.binIndex < 0) {
        [UIAlertView alertWithMessage:@"请选择bin文件"];
        return;
    }
    
    MeshOTAItemModel *model = self.array[self.itemIndex];
    [self userAbled:NO];

    [[MeshOTAManager share] startMeshOTAWithDeviceType:model.deviceType otaData:self.binDataArray[self.binIndex] progressHandle:^(MeshOTAState meshState, NSInteger progress) {
        if (meshState == MeshOTAState_normal) {
            //点对点OTA阶段
            NSString *t = [NSString stringWithFormat:@"ota firmware push... progress:%ld%%", (long)progress];
            NSLog(@"t = %@",t);
//            ARShowTips.shareTips.showTip(t);
        }else if (meshState == MeshOTAState_continue){
            //meshOTA阶段
            NSString *t = [NSString stringWithFormat:@"package meshing... progress:%ld%%", (long)progress];
//            ARShowTips.shareTips.showTip(t);
            NSLog(@"t = %@",t);
        }
    } finishHandle:^(NSInteger successNumber, NSInteger failNumber) {
        NSString *tip = [NSString stringWithFormat:@"success:%ld,fail:%ld", (long)successNumber, (long)failNumber];
        [UIAlertView alertWithMessage:tip];
        [self userAbled:YES];
    } errorHandle:^(NSError *error) {
        [UIAlertView alertWithMessage:error.domain];
        [self userAbled:YES];
    }];
}

- (void)userAbled:(BOOL)able{
    self.startButton.enabled = able;
    self.tableView.userInteractionEnabled = able;
    [self setStartButtonEnable:able];
}

-(void)dealloc{
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
