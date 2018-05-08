//
//  CentralModel.h
//  TelinkBlueDemo
//
//  Created by telink on 15/12/10.
//  Copyright © 2015年 Green. All rights reserved.
//


#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, LightStataType) {
    LightStataTypeOutline,
    LightStataTypeOn,
    LightStataTypeOff,
};
@interface DeviceModel : NSObject{
@public
    int grpAdress[8];
}
/**
 *地址
*/
@property(nonatomic,assign)uint32_t u_DevAdress;


/**
 *状态－0-离线状态   1-－在线关灯状态  3-－－在线开灯状态
 */

@property(nonatomic,assign)LightStataType stata;

/**
 *亮度－0-到 100；
 */
@property(nonatomic,assign)NSUInteger brightness;



-(BOOL)addGrpAddressPro:(int)addAdr;
-(BOOL)removeGrpAddressPro:(int)addAdr;

- (void)updataLightStata:(DeviceModel *)model;
- (instancetype)initWithModel:(DeviceModel *)model;

@end
