//
//  SymbolViewModel.m
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel.h"
#import "DWBaseModel.h"
#import "DWCalculateHelper.h"

NSInteger const kShowTopNumber = 5;

@interface DWSymbolViewModel ()

@end

@implementation DWSymbolViewModel

- (void)setLinkMapContent:(NSString *)linkMapContent {
    _linkMapContent = linkMapContent;
    [self symbolMapFromContent:linkMapContent];
}

- (NSUInteger)moreThanSize {
    return _moreThanSize == 0 ? 50 : _moreThanSize;
}

- (void)symbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,DWSymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWSymbolModel *>*fileSymbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWFrameWorkModel *>*frameworkSymbolMap = [NSMutableDictionary new];
    // 符号文件列表
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    
    BOOL reachFiles = NO;
    BOOL reachSymbols = NO;
    BOOL reachSections = NO;
    
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"])
                reachFiles = YES;
            else if ([line hasPrefix:@"# Sections:"])
                reachSections = YES;
            else if ([line hasPrefix:@"# Symbols:"])
                reachSymbols = YES;
        } else {
            if(reachFiles == YES && reachSections == NO && reachSymbols == NO) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    DWSymbolModel *symbol = [DWSymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                    fileSymbolMap[symbol.fileName] = symbol;
                    
                    DWFrameWorkModel *setModel = frameworkSymbolMap[symbol.frameworkName];
                    if (setModel) {
                        [setModel.subMap setObject:symbol forKey:symbol.fileName];
                    } else {
                        DWFrameWorkModel *frameworkModel = [DWFrameWorkModel new];
                        frameworkModel.frameworkName = symbol.frameworkName;
                        frameworkModel.subMap = @{symbol.fileName:symbol}.mutableCopy;
                        frameworkSymbolMap[symbol.frameworkName] = frameworkModel;
                    }
                }
            } else if (reachFiles == YES && reachSections == YES && reachSymbols == YES) {
                NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                if(symbolsArray.count == 3) {
                    NSString *fileKeyAndName = symbolsArray[2];
                    NSUInteger size = strtoul([symbolsArray[1] UTF8String], nil, 16);
                    
                    NSRange range = [fileKeyAndName rangeOfString:@"]"];
                    if(range.location != NSNotFound) {
                        NSString *key = [fileKeyAndName substringToIndex:range.location+1];
                        DWSymbolModel *symbol = symbolMap[key];
                        
                        DWFrameWorkModel *setModel = frameworkSymbolMap[symbol.frameworkName];
                        if(symbol) {
                            symbol.size += size;
                            setModel.size += size;
                        }
                    }
                }
            }
        }
    }
    _symbolMap = symbolMap;
    _fileNameSymbolMap = fileSymbolMap;
    _frameworkSymbolMap = frameworkSymbolMap;
}

- (NSArray<DWFrameWorkModel *> *)sortedFrameworks {
    NSArray *sortedSymbols = [self.frameworkSymbolMap.allValues sortedArrayUsingComparator:^NSComparisonResult(DWFrameWorkModel *  _Nonnull obj1, DWFrameWorkModel *  _Nonnull obj2) {
        if (self.sortedDiffSize) {
            if(obj1.differentSize > obj2.differentSize) {
                return NSOrderedAscending;
            } else if (obj1.differentSize < obj2.differentSize) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }
        if(obj1.size > obj2.size) {
            return NSOrderedAscending;
        } else if (obj1.size < obj2.size) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    return sortedSymbols;
}

- (void)buildCompareResult {
    if (self.frameworkAnalyze) {
        [self combineHistoryByFramework];
        [self buildCompareFrameworkResult];
    } else {
        [self combineHistoryByFile];
        [self buildCompareFileResult];
    }
    
}

#pragma make - 按照文件 分析

- (void)combineHistoryByFile {
    NSMutableDictionary *temp = self.historyViewModel.fileNameSymbolMap.mutableCopy;
    for (NSString *fileName in self.fileNameSymbolMap.allKeys) {
        DWSymbolModel *curModel = self.fileNameSymbolMap[fileName];
        DWSymbolModel *hisModel = self.historyViewModel.fileNameSymbolMap[fileName];
        
        curModel.historySize = hisModel.size;
        if (!hisModel) {
            curModel.displayFileName = [NSString stringWithFormat:@"新增 %@",curModel.fileName];
        }
        [temp removeObjectForKey:fileName];
    }
    if (temp.allKeys.count > 0) {
        for (NSString *key in temp.allKeys) {
            DWSymbolModel *hisModel = temp[key];
            DWSymbolModel *model = [[DWSymbolModel alloc] init];
            model.file = hisModel.file;
            model.historySize = hisModel.size;
            model.displayFileName = [NSString stringWithFormat:@"已删除 %@",hisModel.fileName];
            self.fileNameSymbolMap[hisModel.fileName] = model;
        }
    }
}

- (NSArray *)sortedWithArr:(NSArray *)arr {
    NSArray *sortedSymbols = [arr sortedArrayUsingComparator:^NSComparisonResult(DWBaseModel *obj1, DWBaseModel *obj2) {
        if (self.sortedDiffSize) {
            if(obj1.differentSize > obj2.differentSize) {
                return NSOrderedAscending;
            } else if (obj1.differentSize < obj2.differentSize) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        } else {
            if(obj1.size > obj2.size) {
                return NSOrderedAscending;
            } else if (obj1.size < obj2.size) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }
    }];
    return sortedSymbols;
}

- (void)buildCompareFileResult {
    NSArray *frameworks = [self sortedWithArr:self.fileNameSymbolMap.allValues];
    self.result = [@"  序号\t\t当前版本\t\t历史版本\t\t版本差异\t\t文件名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    NSString *searchKey = _searchkey;
    for (int index = 0; index < frameworks.count; index++) {
        DWSymbolModel *symbol = frameworks[index];
        if (searchKey.length > 0) {
            if ([symbol.fileName containsString:searchKey]) {
                [self appendResultWithSumbolModel:symbol index:index+1];
                totalSize += symbol.size;
                hisTotalSize += symbol.historySize;
            }
        } else {
            [self appendResultWithSumbolModel:symbol index:index+1];
            totalSize += symbol.size;
            hisTotalSize += symbol.historySize;
        }
    }
    NSString *diffSizeStr = [DWCalculateHelper calculateDiffSize:totalSize-hisTotalSize];
    [self.result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@  版本差异：%@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize], diffSizeStr];
}

- (void)appendResultWithSumbolModel:(DWSymbolModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"No.%5ld\t\t%@\t\t%@\t\t%@\t\t%@\r\n",index,model.sizeStr, model.historySizeStr, model.differentSizeStr, model.displayFileName];
}

#pragma make - 按照framework 分组

- (void)combineHistoryByFramework {
    NSMutableDictionary *temp = self.historyViewModel.frameworkSymbolMap.mutableCopy;
    for (NSString *key in self.frameworkSymbolMap.allKeys) {
        DWFrameWorkModel *curSetModel = self.frameworkSymbolMap[key];
        DWFrameWorkModel *hisSetModel = self.historyViewModel.frameworkSymbolMap[key];
        
        curSetModel.historySize = hisSetModel.size;
        curSetModel.historySubMap = hisSetModel.subMap;
        if (!hisSetModel) {
            curSetModel.frameworkName = [NSString stringWithFormat:@"新增 %@",curSetModel.frameworkName];
        }
        
        // 只显示top5
        if (_showTop5 || _showMoreThanSize) {
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
                if (_showMoreThanSize && symbolModel.size >= self.moreThanSize*kCalculateConstant) {
                    [subArray addObject:symbolModel];
                } else if (_showMoreThanSize && symbolModel.size < self.moreThanSize*kCalculateConstant) {
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
            setModel.frameworkName = [NSString stringWithFormat:@"已删除 %@",hisSetModel.frameworkName];
            self.frameworkSymbolMap[hisSetModel.frameworkName] = setModel;
        }
    }
}

- (void)buildCompareFrameworkResult {
    NSArray<DWFrameWorkModel *> *frameworks = [self sortedWithArr:self.frameworkSymbolMap.allValues];
    self.result = [@"序号\t\t当前版本\t\t历史版本\t\t版本差异\t\t模块名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    NSString *searchKey = _searchkey;
    for (int index = 0; index < frameworks.count; index++) {
        DWFrameWorkModel *symbol = frameworks[index];
        if (searchKey.length > 0) {
            if ([symbol.frameworkName containsString:searchKey]) {
                [self appendResultWithFrameworkModel:symbol index:index+1];
                totalSize += symbol.size;
                hisTotalSize += symbol.historySize;
            }
        } else {
            [self appendResultWithFrameworkModel:symbol index:index+1];
            totalSize += symbol.size;
            hisTotalSize += symbol.historySize;
        }
    }
    NSString *diffSizeStr = [DWCalculateHelper calculateDiffSize:totalSize-hisTotalSize];
    [self.result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@  版本差异：%@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize], diffSizeStr];
}

- (void)appendResultWithFrameworkModel:(DWFrameWorkModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t\t%@\t\t%@\t\t%@\t\t%@\r\n",index,model.sizeStr, model.historySizeStr, model.differentSizeStr, model.frameworkName];
    if (model.displayArr.count > 0) {
        for (DWSymbolModel *fileModel in model.displayArr) {
            [self.result appendFormat:@"  \t\t%@\t\t%@\t\t%@\t\t%@\r\n",fileModel.sizeStr, fileModel.historySizeStr, fileModel.differentSizeStr, fileModel.fileName];
        }
        [self.result appendFormat:@"\r\n"];
    }
}

- (NSMutableString *)result {
    if (!_result) {
        _result = [[NSMutableString alloc] initWithString:@""];
    }
    return _result;
}

@end
