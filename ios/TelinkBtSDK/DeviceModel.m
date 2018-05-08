
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
}
- (instancetype)initWithModel:(DeviceModel *)model {
    if (self=[super init]) {
        _u_DevAdress = model.u_DevAdress;
        _brightness = model.brightness;
        _stata = model.stata;
    }
    return self;
}
@end
