/********************************************************************************************************
 * @file     BTDevItem+Custom.m 
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
//  BTDevItem+Custom.m
//  TelinkBlueDemo
//
//  Created by Arvin on 2018/2/28.
//  Copyright © 2018年 Green. All rights reserved.
//

#import "BTDevItem+Custom.h"

@implementation BTDevItem (Custom)
- (uint32_t)macValue {
    NSString *mac = [NSString stringWithFormat:@"%x", self.u_Mac];
    NSMutableString *v = [NSMutableString new];
    for (int i=3; i>0; i--) {
        [v appendString:[mac substringWithRange:NSMakeRange(i*2, 2)]];
    }
    return (uint32_t)strtoul([v UTF8String], 0, 16);
}
@end
