//
//  DWSymbolViewModel+CompareLinkMap.m
//  LinkMap
//
//  Created by 王启启 on 2018/8/2.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel+CompareLinkMap.h"

NSInteger const kShowTopNumber = 5;

@implementation DWSymbolViewModel (CompareLinkMap)

- (void)combineHistoryData {
    [self combineHistoryByFramework];
    [self combineHistoryByFile];
}

- (void)buildCompareResult {
    DWSortedStyle style = self.sortedDiffSize ? DWSortedDiffSize : DWSortedSize;
    if (self.frameworkAnalyze) {
        NSArray *frameworks = [self sortedWithArr:self.frameworkSymbolMap.allValues style:style];
        [self buildCompareResult:frameworks isFormeworkSet:YES];
    } else {
        NSArray *fileNames = [self sortedWithArr:self.fileNameSymbolMap.allValues style:style];
        [self buildCompareResult:fileNames isFormeworkSet:NO];
    }
}

#pragma make - 按照文件 分析

- (void)combineHistoryByFile {
    NSMutableDictionary *temp = self.historyViewModel.fileNameSymbolMap.mutableCopy;
    for (NSString *fileName in self.fileNameSymbolMap.allKeys) {
        DWSymbolModel *curModel = (DWSymbolModel *)self.fileNameSymbolMap[fileName];
        DWSymbolModel *hisModel = (DWSymbolModel *)self.historyViewModel.fileNameSymbolMap[fileName];
        
        curModel.historySize = hisModel.size;
        if (!hisModel) {
            curModel.showName = [NSString stringWithFormat:@"新增 %@",curModel.fileName];
        }
        [temp removeObjectForKey:fileName];
    }
    if (temp.allKeys.count > 0) {
        for (NSString *key in temp.allKeys) {
            DWSymbolModel *hisModel = temp[key];
            DWSymbolModel *model = [[DWSymbolModel alloc] init];
            model.file = hisModel.file;
            model.historySize = hisModel.size;
            model.showName = [NSString stringWithFormat:@"已删除 %@",hisModel.fileName];
            self.fileNameSymbolMap[hisModel.fileName] = model;
        }
    }
}

- (void)buildCompareResult:(NSArray *)fileNames isFormeworkSet:(BOOL)isFormeworkSet {
    self.result = [@"序号\t\t当前版本\t\t历史版本\t\t版本差异\t\t 名称 \r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    NSMutableArray *mArr = [NSMutableArray array];
    
    for (int index = 0; index < fileNames.count; index++) {
        DWBaseModel *symbol = fileNames[index];
        if ([self displayCondition]) {
            if ([self containsString:symbol.key]) {
                if (isFormeworkSet) {
                    [self appendResultWithFrameworkModel:symbol index:index+1];
                } else {
                    [self appendResultWithSumbolModel:symbol index:index+1];
                }
                totalSize += symbol.size;
                hisTotalSize += symbol.historySize;
                [mArr addObject:symbol];
            }
        } else {
            if (isFormeworkSet) {
                [self appendResultWithFrameworkModel:symbol index:index+1];
            } else {
                [self appendResultWithSumbolModel:symbol index:index+1];
            }
            totalSize += symbol.size;
            hisTotalSize += symbol.historySize;
            [mArr addObject:symbol];
        }
    }
    self.resultArray = mArr.copy;
    NSString *diffSizeStr = [DWCalculateHelper calculateDiffSize:totalSize-hisTotalSize];
    [self.result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@  版本差异：%@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize], diffSizeStr];
}

- (void)appendResultWithSumbolModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t\t%@\t\t%@\t\t%@\t\t%@\r\n",index,model.sizeStr, model.historySizeStr, model.differentSizeStr, model.showName];
}

#pragma make - 按照framework 分组

- (void)combineHistoryByFramework {
    NSMutableDictionary *temp = self.historyViewModel.frameworkSymbolMap.mutableCopy;
    for (NSString *key in self.frameworkSymbolMap.allKeys) {
        DWFrameWorkModel *curSetModel = (DWFrameWorkModel *)self.frameworkSymbolMap[key];
        DWFrameWorkModel *hisSetModel = (DWFrameWorkModel *)self.historyViewModel.frameworkSymbolMap[key];
        
        curSetModel.historySize = hisSetModel.size;
        curSetModel.historySubMap = hisSetModel.subMap;
        if (!hisSetModel) {
            curSetModel.showName = [NSString stringWithFormat:@"新增 %@",curSetModel.frameworkName];
        }
        
        // 只显示top5
        if (self.showTop5 || self.showMoreThanSize) {
            NSArray *array = self.sortedDiffSize ? curSetModel.sortedDiffSizeSymbols : curSetModel.sortedSymbols;
            NSMutableArray *subArray = [NSMutableArray array];
            NSInteger count = curSetModel.subMap.allValues.count;
            if (self.showTop5) {
                count = array.count > kShowTopNumber ? kShowTopNumber : array.count;
            }
            for (int i = 0; i < count; i++) {
                DWSymbolModel *symbolModel = array[i];
                DWSymbolModel *historySymbolModel = curSetModel.historySubMap[symbolModel.fileName];
                symbolModel.historySize = historySymbolModel.size;
                if (self.showMoreThanSize && symbolModel.size >= self.moreThanSize*kCalculateConstant) {
                    [subArray addObject:symbolModel];
                } else if (self.showMoreThanSize && symbolModel.size < self.moreThanSize*kCalculateConstant) {
                    break;
                } else {
                    [subArray addObject:symbolModel];
                }
            }
            curSetModel.displayArr = subArray.copy;
        }
        [temp removeObjectForKey:key];
    }
    if (temp.allKeys.count > 0) {
        for (NSString *key in temp.allKeys) {
            DWFrameWorkModel *hisSetModel = temp[key];
            DWFrameWorkModel *setModel = [[DWFrameWorkModel alloc] init];
            setModel.subMap = hisSetModel.subMap;
            setModel.historySubMap = hisSetModel.historySubMap;
            setModel.historySize = hisSetModel.size;
            setModel.frameworkName = hisSetModel.frameworkName;
            setModel.showName = [NSString stringWithFormat:@"已删除 %@",hisSetModel.frameworkName];
            self.frameworkSymbolMap[hisSetModel.frameworkName] = setModel;
        }
    }
}

- (void)appendResultWithFrameworkModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t\t%@\t\t%@\t\t%@\t\t%@\r\n",index,model.sizeStr, model.historySizeStr, model.differentSizeStr, model.showName];
    DWFrameWorkModel *frameworkModel = (DWFrameWorkModel *)model;
    if (frameworkModel.displayArr.count > 0) {
        for (int i = 0; i < frameworkModel.displayArr.count; i++) {
            DWSymbolModel *fileModel = frameworkModel.displayArr[i];
            NSString *subIndex = [NSString stringWithFormat:@"%ld_%d",(long)index,i];
            [self.result appendFormat:@"%@\t\t%@\t\t%@\t\t%@\t\t%@\r\n",subIndex,fileModel.sizeStr, fileModel.historySizeStr, fileModel.differentSizeStr, fileModel.fileName];
        }
    }
}


@end
