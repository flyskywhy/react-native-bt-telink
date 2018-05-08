//
//  UIWindow+ARShow.m
//  OTA
//
//  Created by telink on 16/7/12.
//  Copyright © 2016年 Arvin.shi. All rights reserved.
//

#import "UIWindow+ARShow.h"

@implementation UIWindow (ARShow)
- (void)alertShowTips:(NSString *)content {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:content preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"back" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self.rootViewController presentViewController:alert animated:YES completion:nil];
}
@end
