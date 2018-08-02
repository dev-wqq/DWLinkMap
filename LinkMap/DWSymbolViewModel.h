//
//  SymbolViewModel.h
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DWSymbolModel;
@class DWFrameWorkModel;
@interface DWSymbolViewModel : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *,DWSymbolModel *>    *symbolMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *,DWSymbolModel *>    *fileNameSymbolMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *,DWFrameWorkModel *> *frameworkSymbolMap;

@property (nonatomic, strong) NSURL    *linkMapFileURL;
@property (nonatomic, strong) NSString *linkMapContent;

@property (nonatomic, assign) BOOL frameworkAnalyze;
@property (nonatomic, assign) BOOL showTop5;
@property (nonatomic, assign) BOOL showMoreThanSize;
@property (nonatomic, assign) BOOL sortedDiffSize;

@property (nonatomic, copy) NSString *searchkey;

@property (nonatomic, strong) NSMutableString *result;

/// default
@property (nonatomic, assign) NSUInteger moreThanSize;

@property (nonatomic, strong) DWSymbolViewModel *historyViewModel;

- (void)buildCompareResult;

- (NSArray *)sortedWithArr:(NSArray *)arr;

// framework 按照size排序
- (NSArray<DWFrameWorkModel *> *)sortedFrameworks;




@end
