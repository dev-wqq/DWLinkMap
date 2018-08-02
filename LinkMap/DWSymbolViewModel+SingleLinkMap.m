//
//  DWSymbolViewModel+SingleLinkMap.m
//  LinkMap
//
//  Created by 王启启 on 2018/8/2.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel+SingleLinkMap.h"
#import "DWBaseModel.h"
#import "DWCalculateHelper.h"

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
    self.result = [@"序号\t\t文件大小\t\t文件名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSString *searchKey = self.searchkey;
    for (int index = 0; index < frameworks.count; index++) {
        DWBaseModel *symbol = frameworks[index];
        if (searchKey.length > 0) {
            if ([symbol.showName containsString:searchKey]) {
                [self appendResultWithFileModel:symbol index:index+1];
                totalSize += symbol.size;
            }
        } else {
            [self appendResultWithFileModel:symbol index:index+1];
            totalSize += symbol.size;
        }
    }
    [self.result appendFormat:@"\r\n总大小: %@",[DWCalculateHelper calculateSize:totalSize]];
}

- (void)appendResultWithFileModel:(DWBaseModel *)model index:(NSInteger)index {
    [self.result appendFormat:@"%ld\t\t%@\t\t%@\r\n",index,model.sizeStr, model.showName];
    if ([model isKindOfClass:[DWFrameWorkModel class]]) {
        DWFrameWorkModel *framework = (DWFrameWorkModel *)model;
        if (framework.displayArr.count > 0) {
            for (DWSymbolModel *fileModel in framework.displayArr) {
                [self.result appendFormat:@"  \t\t%@\t\t%@\r\n",fileModel.sizeStr, fileModel.showName];
            }
            [self.result appendFormat:@"\r\n"];
        }
    }
}

@end
