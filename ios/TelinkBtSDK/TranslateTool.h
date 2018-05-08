//
//  TranslateTool.h
//  TelinkBlueDemo
//
//  Created by telink on 15/12/9.
//  Copyright © 2015年 Green. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TranslateTool : NSObject

+(NSString *)ToHex:(long long int)tmpid;


+ (NSString *)hexStringFromString:(NSString *)string;



// 十六进制转换为普通字符串的。
+ (NSString *)stringFromHexString:(NSString *)hexString;
@end
