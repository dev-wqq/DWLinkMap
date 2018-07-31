//
//  SymbolViewModel.h
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DWSymbolSetModel;
@interface DWSymbolViewModel : NSObject

@property (nonatomic, strong) NSMutableDictionary *symbolMap;
@property (nonatomic, strong) NSMutableDictionary *fileSymbolMap;
@property (nonatomic, strong) NSMutableDictionary *frameworkSymbolMap;

@property (nonatomic, strong) NSURL *linkMapFileURL;

@property (nonatomic, strong) NSString *linkMapContent;

- (void)symbolMapFromContent:(NSString *)content;

- (NSArray<DWSymbolSetModel *> *)sortSetSymbols;

@end
