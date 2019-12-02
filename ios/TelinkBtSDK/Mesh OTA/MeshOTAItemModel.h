/********************************************************************************************************
 * @file     MeshOTAItemModel.h
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
//  MeshOTAItemModel.h
//  TelinkBlueDemo
//
//  Created by Arvin on 2018/4/18.
//  Copyright © 2018年 Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MeshOTAItemModel : NSObject

@property (nonatomic, assign) NSInteger deviceType;
@property (nonatomic, assign) BOOL  OTAAble;

@end