//
//  SymbolModel.h
//  LinkMap
//
//  Created by Suteki(67111677@qq.com) on 4/8/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SymbolModel : NSObject

@property (nonatomic, copy) NSString *file;//文件
@property (nonatomic, assign) NSUInteger size;//大小

/// 历史版本大小
@property (nonatomic, assign) NSUInteger historySize;
/// 文件名称 库名称(文件名称.o)
@property (nonatomic, copy) NSString *fileName;
/// 库名称
@property (nonatomic, copy) NSString *frameworkName;

@property (nonatomic, strong) NSMutableArray *mArray;

@end

@interface DWSymbolSetModel: NSObject

@property (nonatomic, assign) NSUInteger size;//大小
/// 历史版本大小
@property (nonatomic, assign) NSUInteger historySize;
/// 库名称
@property (nonatomic, copy) NSString *frameworkName;

@property (nonatomic, strong) NSMutableDictionary *subMap;

@property (nonatomic, strong) NSMutableDictionary *historySubMap;

@end
