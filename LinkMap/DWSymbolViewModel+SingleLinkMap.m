//
//  DWSymbolViewModel+SingleLinkMap.m
//  LinkMap
//
//  Created by 王启启 on 2018/8/2.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel+SingleLinkMap.h"

@implementation DWSymbolViewModel (SingleLinkMap)

- (void)buildSingleResult {
    [self buildSingleFrameworkResult];
}

- (void)buildSingleFrameworkResult {
    NSArray<DWBaseModel *> *frameworks = nil;
    if (self.frameworkAnalyze) {
        frameworks = [self sortedWithArr:self.frameworkSymbolMap.allValues];
    } else {
        frameworks = [self sortedWithArr:self.fileNameSymbolMap.allValues];
    }
    self.result = [@"序号\t文件大小\t__Text\t__Data\t文件名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSMutableArray *mArr = [NSMutableArray array];
    for (int index = 0; index < frameworks.count; index++) {
        DWBaseModel *symbol = frameworks[index];
        if ([self displayCondition]) {
            NSString *frameworkName = symbol.key;
            if ([symbol isKindOfClass:[DWSymbolModel class]]) {
                frameworkName = ((DWSymbolModel *)symbol).frameworkName;
            }
            if ([self containsString:symbol.key frameworkName:frameworkName]) {
                [self appendResultWithFileModel:symbol index:index+1];
                totalSize += symbol.total.size;
                [mArr addObject:symbol];
            }
        } else {
            [self appendResultWithFileModel:symbol index:index+1];
            totalSize += symbol.total.size;
            [mArr addObject:symbol];
        }
    }
    self.resultArray = mArr.copy;

    [self.result appendFormat:@"\r\n__TextSize: %@\t%@",[DWCalculateHelper calculateSize:self.totalTextSize], @(self.totalTextSize)];
    [self.result appendFormat:@"\r\n__DataSize: %@\t%@",[DWCalculateHelper calculateSize:self.totalDataSize], @(self.totalDataSize)];
    [self.result appendFormat:@"\r\n总大小: %@",[DWCalculateHelper calculateSize:totalSize]];
}

- (void)appendResultWithFileModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t%@\t%@\t%@\t%@\r\n",index,model.total.sizeStr,model.text.sizeStr,model.data.sizeStr, model.showName];
    if ([model isKindOfClass:[DWFrameWorkModel class]]) {
        DWFrameWorkModel *framework = (DWFrameWorkModel *)model;
        if (framework.displayArr.count > 0) {
            for (DWSymbolModel *fileModel in framework.displayArr) {
                [self.result appendFormat:@"  \t%@\t%@\t%@\t%@\r\n",fileModel.total.sizeStr,model.text.sizeStr,model.data.sizeStr, fileModel.showName];
            }
            [self.result appendFormat:@"\r\n"];
        }
    }
}

@end
