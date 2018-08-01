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
    _fileSymbolMap = fileSymbolMap;
    _frameworkSymbolMap = frameworkSymbolMap;
}

- (NSArray<DWFrameWorkModel *> *)sortedFrameworks {
    
    NSArray *sortedSymbols = [self.frameworkSymbolMap.allValues sortedArrayUsingComparator:^NSComparisonResult(DWFrameWorkModel *  _Nonnull obj1, DWFrameWorkModel *  _Nonnull obj2) {
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
    }
    
}


- (void)combineHistoryByFile {
    
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
    NSArray<DWFrameWorkModel *> *frameworks = [self sortedFrameworks];
    self.result = [@"序号\t\t当前版本\t\t历史版本\t\t版本差异\t\t模块名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    NSString *searchKey = _searchkey;
    for (int index = 0; index < frameworks.count; index++) {
        DWFrameWorkModel *symbol = frameworks[index];
        if (searchKey.length > 0) {
            if ([symbol.frameworkName containsString:searchKey]) {
                [self appendResultWithSetSymbol:symbol index:index+1];
                totalSize += symbol.size;
                hisTotalSize += symbol.historySize;
            }
        } else {
            [self appendResultWithSetSymbol:symbol index:index+1];
            totalSize += symbol.size;
            hisTotalSize += symbol.historySize;
        }
    }
    [_result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize]];
}

- (void)appendResultWithSetSymbol:(DWFrameWorkModel *)model index:(NSInteger)index {
    [_result appendFormat:@"%ld\t\t%@\t\t%@\t\t%@\t\t%@\r\n",index,model.sizeStr, model.historySizeStr, model.differentSizeStr, model.frameworkName];
    if (model.displayArr.count > 0) {
        for (DWSymbolModel *fileModel in model.displayArr) {
            [_result appendFormat:@"  \t\t%@\t\t%@\t\t%@\t\t%@\r\n",fileModel.sizeStr, fileModel.historySizeStr, fileModel.differentSizeStr, fileModel.fileName];
        }
        [_result appendFormat:@"\r\n"];
    }
}

- (NSMutableString *)result {
    if (!_result) {
        _result = [[NSMutableString alloc] initWithString:@""];
    }
    return _result;
}

@end
