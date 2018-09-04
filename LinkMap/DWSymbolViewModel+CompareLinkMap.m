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
        
        curModel.total.historySize = hisModel.total.size;
        curModel.text.historySize = hisModel.text.size;
        curModel.data.historySize = hisModel.data.size;
        if (!hisModel) {
            curModel.showName = [NSString stringWithFormat:@"新增 %@ %@",curModel.fileName, @(curModel.total.size).stringValue];
        }
        [temp removeObjectForKey:fileName];
    }
    if (temp.allKeys.count > 0) {
        for (NSString *key in temp.allKeys) {
            DWSymbolModel *hisModel = temp[key];
            DWSymbolModel *model = [[DWSymbolModel alloc] init];
            model.file = hisModel.file;
            model.total.historySize = hisModel.total.size;
            model.text.historySize  = hisModel.text.size;
            model.data.historySize  = hisModel.data.size;
            model.showName = [NSString stringWithFormat:@"已删除 %@ %@",hisModel.frameworkName, @(hisModel.total.historySize).stringValue];
            self.fileNameSymbolMap[hisModel.fileName] = model;
        }
    }
}

- (void)buildCompareResult:(NSArray *)fileNames isFormeworkSet:(BOOL)isFormeworkSet {
    self.result = [@"序号\t当前版本\t历史版本\t版本差异\t文件大小\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    NSMutableArray *mArr = [NSMutableArray array];
    
    for (int index = 0; index < fileNames.count; index++) {
        DWBaseModel *symbol = fileNames[index];
        if ([self displayCondition]) {
            NSString *frameworkName = symbol.key;
            if ([symbol isKindOfClass:[DWSymbolModel class]]) {
                frameworkName = ((DWSymbolModel *)symbol).frameworkName;
            }
            if ([self containsString:symbol.key frameworkName:frameworkName]) {
                if (isFormeworkSet) {
                    [self appendResultWithFrameworkModel:symbol index:index+1];
                } else {
                    [self appendResultWithSumbolModel:symbol index:index+1];
                }
                totalSize += symbol.total.size;
                hisTotalSize += symbol.total.historySize;
                [mArr addObject:symbol];
            }
        } else {
            if (isFormeworkSet) {
                [self appendResultWithFrameworkModel:symbol index:index+1];
            } else {
                [self appendResultWithSumbolModel:symbol index:index+1];
            }
            totalSize += symbol.total.size;
            hisTotalSize += symbol.total.historySize;
            [mArr addObject:symbol];
        }
    }
    self.resultArray = mArr.copy;
    
    NSInteger diff = self.totalTextSize-self.historyViewModel.totalTextSize;
    NSString *diffSizeStr = [DWCalculateHelper calculateDiffSize:diff];
    [self.result appendFormat:@"\r\n当前__TextSize: %@\t历史__TextSize: %@\t版本差异：%@\r\n",[DWCalculateHelper calculateSize:self.totalTextSize],[DWCalculateHelper calculateSize:self.historyViewModel.totalTextSize], diffSizeStr];
    
    [self.result appendFormat:@"\r\n当前__TextSize: %@\t历史__TextSize: %@\t版本差异：%@\r\n",@(self.totalTextSize),@(self.historyViewModel.totalTextSize), @(diff)];
    
    
//    diff = self.totalDataSize-self.historyViewModel.totalDataSize;
//    diffSizeStr = [DWCalculateHelper calculateDiffSize:diff];
//    [self.result appendFormat:@"\r\n当前__DataSize: %@\t历史__DataSize: %@\t版本差异：%@\r\n\t版本差异：%@\r\n",[DWCalculateHelper calculateSize:self.totalDataSize],[DWCalculateHelper calculateSize:self.historyViewModel.totalDataSize], diffSizeStr,@(diff).stringValue];
    
    diff = totalSize-hisTotalSize;
    diffSizeStr = [DWCalculateHelper calculateDiffSize:diff];
    [self.result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@  版本差异：%@\r\n\t版本差异：%@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize], diffSizeStr,@(diff).stringValue];
}

- (void)appendResultWithSumbolModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t%@\t%@\t%@\t%@\r\n",index,model.total.sizeStr, model.total.historySizeStr, model.total.differentSizeStr, model.showName];
}

#pragma make - 按照framework 分组

- (void)combineHistoryByFramework {
    NSMutableDictionary *temp = self.historyViewModel.frameworkSymbolMap.mutableCopy;
    for (NSString *key in self.frameworkSymbolMap.allKeys) {
        DWFrameWorkModel *curSetModel = (DWFrameWorkModel *)self.frameworkSymbolMap[key];
        DWFrameWorkModel *hisSetModel = (DWFrameWorkModel *)self.historyViewModel.frameworkSymbolMap[key];
        
        curSetModel.total.historySize = hisSetModel.total.size;
        curSetModel.historySubMap = hisSetModel.subMap;
        if (!hisSetModel) {
            curSetModel.showName = [NSString stringWithFormat:@"新增 %@ %@",curSetModel.frameworkName, @(curSetModel.total.size).stringValue];
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
                symbolModel.total.historySize = historySymbolModel.total.size;
                if (self.showMoreThanSize && symbolModel.total.size >= self.moreThanSize*kCalculateConstant) {
                    [subArray addObject:symbolModel];
                } else if (self.showMoreThanSize && symbolModel.total.size < self.moreThanSize*kCalculateConstant) {
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
            setModel.total.historySize = hisSetModel.total.size;
            setModel.frameworkName = hisSetModel.frameworkName;
            setModel.showName = [NSString stringWithFormat:@"已删除 %@ %@",hisSetModel.frameworkName, @(setModel.total.historySize).stringValue];
            self.frameworkSymbolMap[hisSetModel.frameworkName] = setModel;
        }
    }
}

- (void)appendResultWithFrameworkModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t%@\t%@\t%@\t%@\r\n",index,model.total.sizeStr, model.total.historySizeStr, model.total.differentSizeStr, model.showName];
    DWFrameWorkModel *frameworkModel = (DWFrameWorkModel *)model;
    if (frameworkModel.displayArr.count > 0) {
        for (int i = 0; i < frameworkModel.displayArr.count; i++) {
            DWSymbolModel *fileModel = frameworkModel.displayArr[i];
            NSString *subIndex = [NSString stringWithFormat:@"%ld_%d",(long)index,i];
            [self.result appendFormat:@"%@\t%@\t%@\t%@\t%@\r\n",subIndex,fileModel.total.sizeStr, fileModel.total.historySizeStr, fileModel.total.differentSizeStr, fileModel.showName];
        }
    }
}


@end
