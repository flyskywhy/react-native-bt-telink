//
//  BTDevItem.m
//  TelinkBlue
//
//  Created by Green on 11/14/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import "BTDevItem.h"

@implementation BTDevItem
@synthesize devIdentifier;
@synthesize name;
@synthesize blDevInfo;
@synthesize u_Name;
@synthesize u_Vid;
@synthesize u_Pid;
@synthesize u_Mac;
@synthesize rssi;
@synthesize isConnected;
@synthesize isBreakOff;
@synthesize isSeted;
@synthesize u_meshUuid;
@synthesize u_DevAdress;
@synthesize u_Status;
@synthesize isSetedSuff;

@synthesize productID;

- (instancetype)initWithDevice:(BTDevItem *)item {
    if (self=[super init]) {
        devIdentifier = item.devIdentifier;
        name = item.name;
        u_DevAdress = item.u_DevAdress;
        blDevInfo = item.blDevInfo;
        u_Name = item.u_Name;
        u_Vid = item.u_Vid;
        u_Mac = item.u_Mac;
        rssi = item.rssi;
        isConnected = item.isConnected;
    }
    return self;
}

-(id)init
{
    self=[super init];
    [self initData];
    return self;
}

-(void)initData
{
    self.isBreakOff=NO;
    self.isConnected=NO;
    self.isSeted=NO;
    self.isSetedSuff=NO;
}

- (NSString *)uuidString {
    return self.blDevInfo.identifier.UUIDString;
}

- (NSString *)description {
    //stringWithFormat 格式化字符串函数
    return [NSString stringWithFormat:@"name=%@, vid=%u, pid=%u, mac=%x, meshuuid=%u, devadress=%x, status=%u, nnn=%@, rssi=%d, UUIDString=%@", u_Name, u_Vid, u_Pid, u_Mac, u_meshUuid, u_DevAdress, u_Status, blDevInfo.name, rssi, self.blDevInfo.identifier.UUIDString];
}

@end
