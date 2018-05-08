//
//  UIWindow+ARShow.h
//  OTA
//
//  Created by telink on 16/7/12.
//  Copyright © 2016年 Arvin.shi. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kWindow ([UIApplication sharedApplication].keyWindow)
#define kWindowShow(tips) ([kWindow alertShowTips:tips])
@interface UIWindow (ARShow)

- (void)alertShowTips:(NSString *)content;
@end
