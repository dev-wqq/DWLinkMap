//
//  DWSymbolViewModel+ExportExecl.m
//  LinkMap
//
//  Created by 王启启 on 2018/8/2.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel+ExportExecl.h"
#import <xlsxwriter/xlsxwriter.h>

static lxw_format *_knameFormat;// 各表格标题栏的格式

static NSString * const kCurrentVersion = @"v7.0.14";
static NSString * const kHistoryVersion = @"v7.0.12";

@implementation DWSymbolViewModel (ExportExecl)

- (void)exportCompareVersionExecl:(NSString *)fileName {
    if (self.resultArray.count == 0) {
        return;
    }
    lxw_workbook *workbook = workbook_new(fileName.UTF8String);
    lxw_worksheet *worksheet = workbook_add_worksheet(workbook, NULL);
    NSString *moduleName = self.frameworkAnalyze ? @"模块名称" : @"文件名称";
    NSArray *titles = @[@"序号", kCurrentVersion, kHistoryVersion,@"版本差异", moduleName];
    [self addCompareTitleForWorksheet:worksheet titles:titles];
    [self addEportDataAddSubFile:worksheet dataSource:self.resultArray];
    workbook_close(workbook);
}

- (void)exportSingleExecl:(NSString *)fileName {
    if (self.resultArray.count == 0) {
        return;
    }
    lxw_workbook *workbook = workbook_new(fileName.UTF8String);
    lxw_worksheet *worksheet = workbook_add_worksheet(workbook, NULL);
    NSString *moduleName = self.frameworkAnalyze ? @"模块名称" : @"文件名称";
    NSArray *titles = @[@"序号", kCurrentVersion, moduleName];
    [self addCompareTitleForWorksheet:worksheet titles:titles];
    [self addCompareContentForWorksheet:worksheet dataSource:self.resultArray];
    workbook_close(workbook);
}

- (NSArray *)makeModuleWhitelistData:(NSArray *)dataSource {
    if (!self.whitelistURL || self.whitelistSet.count == 0) {
        return nil;
    }
    NSMutableArray *mArr = [NSMutableArray array];
    for (DWFrameWorkModel *model in dataSource) {
        if ([self.whitelistSet containsObject:model.frameworkName]) {
            [mArr addObject:model];
        }
    }
    return mArr;
}

- (void)exportReportDataWithFileName:(NSString *)fileName {
    lxw_workbook *workbook = workbook_new(fileName.UTF8String);
    // 所有模块，通过模块大小降序排序
    NSArray *dataSource = self.frameworkSymbolMap.allValues;
    NSArray *frameworks = [self sortedWithArr:dataSource];
    [self makeReportSheetWithWorkbook:workbook
                            sheetName:self.c_allSSSheet
                           dataSource:frameworks];
    
    // 所有模块，通过版本对比大小降序排序
    frameworks = [self sortedWithArr:self.frameworkSymbolMap.allValues style:DWSortedDiffSize];
    [self makeReportSheetWithWorkbook:workbook
                            sheetName:self.c_allSDSSheet
                           dataSource:frameworks];
    
    
    NSArray *whitelist = [self makeModuleWhitelistData:self.frameworkSymbolMap.allValues];
    
    if (whitelist.count > 0) {
        // 所有名单内，通过版本对比大小降序排序
        NSArray *sortedArr = [self sortedWithArr:whitelist];
        [self makeReportSheetWithWorkbook:workbook
                                sheetName:self.c_whitelistSSSheet
                               dataSource:sortedArr];
        
        // 所有名单内，通过版本对比大小降序排序
        NSArray *sortedDifffArr = [self sortedWithArr:whitelist style:DWSortedDiffSize];
        [self makeReportSheetWithWorkbook:workbook
                                sheetName:self.c_whitelistSSDSheet
                               dataSource:sortedDifffArr];
        
        char const *sheetName = [self c_charFromString:@"sh_group_add"];
        [self makeGroupAddSheetWithWorkbook:workbook sheetName:sheetName dataSource:sortedArr];
    }
    workbook_close(workbook);
}

- (void)makeReportSheetWithWorkbook:(lxw_workbook *)workbook
                    sheetName:(const char*)sheetName
                   dataSource:(NSArray *)dataSource {
    lxw_worksheet *worksheet = workbook_add_worksheet(workbook, sheetName);
    [self addCompareTitleForWorksheet:worksheet titles:[self dw_compareTitles]];
    [self addCompareContentForWorksheet:worksheet dataSource:dataSource];
}

- (void)makeGroupAddSheetWithWorkbook:(lxw_workbook *)workbook
                          sheetName:(const char*)sheetName
                         dataSource:(NSArray *)dataSource  {
    lxw_worksheet *worksheet = workbook_add_worksheet(workbook, sheetName);
    [self addCompareTitleForWorksheet:worksheet titles:[self dw_compareTitles]];
    [self addEportCustomDataAddSubFile:worksheet dataSource:dataSource];
}

/// add sheet titles
- (void)addCompareTitleForWorksheet:(lxw_worksheet *)worksheet
                             titles:(NSArray *)titles {
    for (int i = 0; i < titles.count; i++) {
        NSString *title = titles[i];
        char const *c_title = [title cStringUsingEncoding:NSUTF8StringEncoding];
        worksheet_write_string(worksheet, 0, i, c_title, _knameFormat);
    }
}

#pragma mark - Compare Version Methods

/// 添加内容数据
- (void)addEportDataAddSubFile:(lxw_worksheet *)worksheet
                    dataSource:(NSArray *)dataSource {
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    int totalNumber = 0;
    for (int index = 0; index < dataSource.count; index++) {
        DWBaseModel *model = dataSource[index];
        totalNumber = totalNumber + 2;
        [self addCompareRowForWorkSheet:worksheet model:model indexName:@(index+1).stringValue index:totalNumber];
        if ([model isKindOfClass:[DWFrameWorkModel class]] &&
            ((DWFrameWorkModel *)model).displayArr.count > 0) {
            DWFrameWorkModel *frameworkModel = (DWFrameWorkModel *)model;
            int indexSorted = 0;
            for (int j = 0; j < frameworkModel.displayArr.count; j++) {
                DWBaseModel *subModel = frameworkModel.displayArr[j];
                if (subModel.differentSize != 0) {
                    totalNumber++;
                    indexSorted++;
                    NSString *indexName = [NSString stringWithFormat:@"%d_%d",index+1,indexSorted];
                    [self addCompareRowForWorkSheet:worksheet model:subModel indexName:indexName index:totalNumber];
                }
            }
        }
        totalSize += model.size;
        hisTotalSize += model.historySize;
    }
    NSInteger lastIndex = totalNumber+2;
    [self addCompareTotalForWorkSheet:worksheet
                            totalSize:totalSize
                         hisTotalSize:hisTotalSize
                            lastIndex:(int)lastIndex];
}

/// 添加内容数据
- (void)addEportCustomDataAddSubFile:(lxw_worksheet *)worksheet
                    dataSource:(NSArray *)dataSource {
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    int totalNumber = 0;
    for (int index = 0; index < dataSource.count; index++) {
        DWBaseModel *model = dataSource[index];
        totalNumber = totalNumber + 2;
        [self addCompareRowForWorkSheet:worksheet model:model indexName:@(index+1).stringValue index:totalNumber];
        if ([model isKindOfClass:[DWFrameWorkModel class]]) {
            DWFrameWorkModel *frameworkModel = (DWFrameWorkModel *)model;
            NSArray *sortedArr = [self sortedWithArr:frameworkModel.subMap.allValues];
            int indexSorted = 0;
            for (int j = 0; j < sortedArr.count; j++) {
                DWBaseModel *subModel = sortedArr[j];
                if (subModel.differentSize != 0) {
                    totalNumber++;
                    indexSorted++;
                    NSString *indexName = [NSString stringWithFormat:@"%d_%d",index+1,indexSorted];
                    [self addCompareRowForWorkSheet:worksheet model:subModel indexName:indexName index:totalNumber];
                }
            }
        }
        totalSize += model.size;
        hisTotalSize += model.historySize;
    }
    NSInteger lastIndex = totalNumber+2;
    [self addCompareTotalForWorkSheet:worksheet
                            totalSize:totalSize
                         hisTotalSize:hisTotalSize
                            lastIndex:(int)lastIndex];
}

/// 添加内容数据
- (void)addCompareContentForWorksheet:(lxw_worksheet *)worksheet
                           dataSource:(NSArray *)dataSource  {
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    for (int index = 0; index < dataSource.count; index++) {
        DWBaseModel *model = dataSource[index];
        
        [self addCompareRowForWorkSheet:worksheet model:model index:index+1];
        totalSize += model.size;
        hisTotalSize += model.historySize;
    }
    NSInteger lastIndex = dataSource.count + 1;
    [self addCompareTotalForWorkSheet:worksheet
                            totalSize:totalSize
                         hisTotalSize:hisTotalSize
                            lastIndex:(int)lastIndex];
}

- (void)addCompareRowForWorkSheet:(lxw_worksheet *)worksheet
                            model:(DWBaseModel *)model
                            index:(int)index {
    return [self addCompareRowForWorkSheet:worksheet model:model indexName:@(index).stringValue index:index];
}

/// 添加每一条数据
- (void)addCompareRowForWorkSheet:(lxw_worksheet *)worksheet
                            model:(DWBaseModel *)model
                        indexName:(NSString *)indexName
                            index:(int)index {
    int row = 0;
    char const *c_number = [indexName cStringUsingEncoding:NSUTF8StringEncoding];
    worksheet_write_string(worksheet, index, row, c_number, _knameFormat);
    row++;
    
    char const *c_current = [model.sizeStr cStringUsingEncoding:NSUTF8StringEncoding];
    worksheet_write_string(worksheet, index, row, c_current, _knameFormat);
    row++;
    
    if (self.historyViewModel) {
        char const *c_history = [model.historySizeStr cStringUsingEncoding:NSUTF8StringEncoding];
        worksheet_write_string(worksheet, index, row, c_history, _knameFormat);
        row++;
        
        char const *c_diff = [model.differentSizeStr cStringUsingEncoding:NSUTF8StringEncoding];
        worksheet_write_string(worksheet, index, row, c_diff, _knameFormat);
        row++;
    }
    
    char const *c_fileName = [model.showName cStringUsingEncoding:NSUTF8StringEncoding];
    worksheet_write_string(worksheet, index, row, c_fileName, _knameFormat);
}

/// 添加总计cell
- (void)addCompareTotalForWorkSheet:(lxw_worksheet *)worksheet
                          totalSize:(NSUInteger)totalSize
                       hisTotalSize:(NSUInteger)hisTotalSize
                          lastIndex:(int)lastIndex {
    worksheet_write_string(worksheet, (int)lastIndex, 0, "", _knameFormat);
    lastIndex++;
    
    char const *c_total = [@"总计：" cStringUsingEncoding:NSUTF8StringEncoding];
    worksheet_write_string(worksheet, (int)lastIndex, 0, c_total, _knameFormat);
    
    NSString *str = [DWCalculateHelper calculateSize:totalSize];
    char const *c_str = [[NSString stringWithFormat:@"%@",str] cStringUsingEncoding:NSUTF8StringEncoding];
    worksheet_write_string(worksheet, (int)lastIndex, 1, c_str, _knameFormat);
    
    if (self.historyViewModel) {
        NSString *hisStr = [DWCalculateHelper calculateSize:hisTotalSize];
        char const *c_hisStr = [[NSString stringWithFormat:@"%@",hisStr] cStringUsingEncoding:NSUTF8StringEncoding];
        
        NSString *diffStr = [DWCalculateHelper calculateDiffSize:totalSize-hisTotalSize];
        char const *c_diffStr = [[NSString stringWithFormat:@"%@",diffStr] cStringUsingEncoding:NSUTF8StringEncoding];
        
        worksheet_write_string(worksheet, (int)lastIndex, 2, c_hisStr, _knameFormat);
        worksheet_write_string(worksheet, (int)lastIndex, 3, c_diffStr, _knameFormat);
    }
}

#pragma make - Helper Methods


- (NSArray *)dw_compareTitles {
    return @[@"序号", kCurrentVersion, kHistoryVersion,@"版本差异",@"模块名称"];
}

- (NSArray *)dw_singleTitles {
    return @[@"序号",kCurrentVersion, @"模块名称"];
}

- (const char *)c_charFromString:(NSString *)str {
    if (str) {
        return [str cStringUsingEncoding:NSUTF8StringEncoding];
    } else {
        return NULL;
    }
}

/// ss -> sorted size  sd -> sorted different size
- (const char *)c_allSSSheet {
    return [self c_charFromString:@"all_sorted_size"];
}

- (const char *)c_allSDSSheet {
    return [self c_charFromString:@"all_sorted_diff_size"];
}

- (const char *)c_whitelistSSSheet {
    return [self c_charFromString:@"white_list_sorted_size"];
}

- (const char *)c_whitelistSSDSheet {
    return [self c_charFromString:@"white_list_sorted_diff_size"];
}

@end
