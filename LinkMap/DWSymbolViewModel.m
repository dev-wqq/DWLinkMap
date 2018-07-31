//
//  SymbolViewModel.m
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel.h"
#import "SymbolModel.h"

@interface DWSymbolViewModel ()

@end

@implementation DWSymbolViewModel

- (void)setLinkMapContent:(NSString *)linkMapContent {
    _linkMapContent = linkMapContent;
    [self symbolMapFromContent:linkMapContent];
}

- (void)symbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,SymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,SymbolModel *>*fileSymbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWSymbolSetModel *>*frameworkSymbolMap = [NSMutableDictionary new];
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
                    SymbolModel *symbol = [SymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                    fileSymbolMap[symbol.fileName] = symbol;
                    
                    DWSymbolSetModel *setModel = frameworkSymbolMap[symbol.frameworkName];
                    if (setModel) {
                        [setModel.subMap setObject:symbol forKey:symbol.fileName];
                    } else {
                        DWSymbolSetModel *frameworkModel = [DWSymbolSetModel new];
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
                        SymbolModel *symbol = symbolMap[key];
                        
                        DWSymbolSetModel *setModel = frameworkSymbolMap[symbol.frameworkName];
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


- (NSArray<DWSymbolSetModel *> *)sortSetSymbols {
    NSArray *sortedSymbols = [self.frameworkSymbolMap.allValues sortedArrayUsingComparator:^NSComparisonResult(DWSymbolSetModel *  _Nonnull obj1, DWSymbolSetModel *  _Nonnull obj2) {
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

@end
