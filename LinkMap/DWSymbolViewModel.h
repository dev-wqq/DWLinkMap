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
@property (nonatomic, strong) NSMutableDictionary<NSString *,DWSymbolModel *>    *fileSymbolMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *,DWFrameWorkModel *> *frameworkSymbolMap;

@property (nonatomic, strong) NSURL    *linkMapFileURL;
@property (nonatomic, strong) NSString *linkMapContent;

- (void)symbolMapFromContent:(NSString *)content;

- (void)combineHistoryViewModel:(DWSymbolViewModel *)historyViewModel;

// framework 按照size排序
- (NSArray<DWFrameWorkModel *> *)sortedFrameworks;


@end
