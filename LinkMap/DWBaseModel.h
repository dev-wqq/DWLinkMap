//
//  SymbolModel.h
//  LinkMap
//
//  
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DWBaseModel: NSObject

/// 当前版本size
@property (nonatomic, assign)           NSInteger size;//大小
@property (nonatomic, copy, readonly)   NSString  *sizeStr;
/// 历史版本size
@property (nonatomic, assign)           NSInteger historySize;
@property (nonatomic, copy, readonly)   NSString  *historySizeStr;
/// 版本差异size size - historySize
@property (nonatomic, assign, readonly) NSInteger differentSize;
@property (nonatomic, copy  , readonly) NSString *differentSizeStr;

- (NSString *)showName;

@end

@interface DWSymbolModel : DWBaseModel

/// 文件路径
@property (nonatomic, copy) NSString *file;
/// 文件名称 库名称(文件名称.o)
@property (nonatomic, copy, readonly) NSString *fileName;
/// 库名称
@property (nonatomic, copy, readonly) NSString *frameworkName;

@property (nonatomic, copy) NSString *displayFileName;

@end

@interface DWFrameWorkModel: DWBaseModel
/// 库名称
@property (nonatomic, copy) NSString *frameworkName;
/// 当前版本所有子文件
@property (nonatomic, strong)           NSMutableDictionary<NSString *,DWSymbolModel *> *subMap;
/// 历史版本所有子文件
@property (nonatomic, strong)           NSMutableDictionary<NSString *,DWSymbolModel *> *historySubMap;
/// 根据规则在界面上显示内容
@property (nonatomic, strong)           NSArray<DWSymbolModel *> *displayArr;

- (NSArray<DWSymbolModel *> *)sortedSymbols;
- (NSArray<DWSymbolModel *> *)sortedDiffSizeSymbols;

@end
