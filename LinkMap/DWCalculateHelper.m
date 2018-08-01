//
//  DWCalculateHelper.m
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWCalculateHelper.h"

CGFloat const kCalculateConstant = 1000.0;

@implementation DWCalculateHelper

+ (NSString *)calculateDiffSize:(NSInteger)size {
    NSString *sizeStr = nil;
    NSInteger temp = size / kCalculateConstant / kCalculateConstant;
    NSString *add = size > 0.0 ? @"+" : @"";
    if (temp >= 1.0 || temp <= -1.0) {
        sizeStr = [NSString stringWithFormat:@"%@%.2fM", add, size / kCalculateConstant / kCalculateConstant];
    } else {
        sizeStr = [NSString stringWithFormat:@"%@%.2fK", add, size / kCalculateConstant];
    }
    return sizeStr;
}

+ (NSString *)calculateSize:(NSInteger)size {
    NSString *sizeStr = nil;
    NSInteger temp = size / kCalculateConstant / kCalculateConstant;
    if (temp >= 1.0) {
        sizeStr = [NSString stringWithFormat:@"%.2fM", size / kCalculateConstant / kCalculateConstant];
    } else {
        sizeStr = [NSString stringWithFormat:@"%.2fK", size / kCalculateConstant];
    }
    return sizeStr;
}

@end

