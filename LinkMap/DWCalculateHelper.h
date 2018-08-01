//
//  DWCalculateHelper.h
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>

/// apple 可执行文件大小计算为 1M = 1000*1000B
extern CGFloat const kCalculateConstant;

@interface DWCalculateHelper : NSObject

+ (NSString *)calculateDiffSize:(NSInteger)size;

+ (NSString *)calculateSize:(NSInteger)size;

@end
