//
//  SymbolViewModel.m
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import "DWSymbolViewModel.h"
#import <Cocoa/Cocoa.h>

@interface DWSymbolViewModel ()

@end

@implementation DWSymbolViewModel

#pragma make - Public Methods

- (NSArray *)sortedWithArr:(NSArray *)arr {
    return [self sortedWithArr:arr style:DWSortedSize];
}

- (NSArray *)sortedWithArr:(NSArray *)arr style:(DWSortedStyle)style {
    NSArray *sortedSymbols = [arr sortedArrayUsingComparator:^NSComparisonResult(DWBaseModel *obj1, DWBaseModel *obj2) {
        switch (style) {
            case DWSortedSize:
                return [self compare:obj1.size otherSize:obj2.size];
            case DWSortedHistorySize:
                return [self compare:obj1.historySize otherSize:obj2.historySize];
            case DWSortedDiffSize:
                return [self compare:obj1.differentSize otherSize:obj2.differentSize];
        }
        return [self compare:obj1.size otherSize:obj2.size];
    }];
    return sortedSymbols;
}
- (void)beginWithCompletionHandler:(void(^)(BOOL result, NSURL *url, NSString *path))handler {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (!handler) {
            return ;
        }
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[panel URLs] objectAtIndex:0];
            NSString *filePath = url.path;
            handler(YES, url, filePath);
        } else {
            handler(NO, nil, nil);
        }
    }];
}

- (void)extracted:(void (^)(BOOL, NSURL *, NSString *))handler panel:(NSOpenPanel *)panel {
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (!handler) {
            return ;
        }
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [[panel URLs] objectAtIndex:0];
            NSString *filePath = url.path;
            handler(YES, url, filePath);
        } else {
            handler(NO, nil, nil);
        }
    }];
}

- (void)writeContentWithCompletionHandler:(void(^)(BOOL result, NSURL *url, NSString *path))handler {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = NO;
    
    [self extracted:handler panel:panel];
}


- (void)makeWhitelistSet:(NSString *)content {
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    self.whitelistSet = [NSSet setWithArray:lines];
}

- (void)makeMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,DWSymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWSymbolModel *>*fileSymbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWFrameWorkModel *>*frameworkSymbolMap = [NSMutableDictionary new];
    // 符号文件列表
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    
    BOOL reachFiles = NO;
    BOOL reachSymbols = NO;
    BOOL reachSections = NO;
    BOOL isFirstToData = YES;
    
    NSString *firstDataAddress = nil;
    NSString *lastDataAddress = nil;
    NSString *lastDataSize    = nil;
    NSUInteger totalTextSize = 0;
    NSUInteger totalDataSize = 0;
    
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"]) {
                reachFiles = YES;
            } else if ([line hasPrefix:@"# Sections:"]) {
                reachSections = YES;
            } else if ([line hasPrefix:@"# Symbols:"]) {
                // 获取 __Data size
                totalDataSize = [self getSizeFromMAddress:lastDataAddress] - [self getSizeFromMAddress:firstDataAddress] + [self getSizeFromHex:lastDataSize];
                reachSymbols = YES;
            }
        } else {
            if(reachFiles == YES && reachSections == NO && reachSymbols == NO) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    DWSymbolModel *symbol = [DWSymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    // [ 0] 文件编号
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
            } else if (reachFiles == YES && reachSections == YES && reachSymbols == NO) {
                // 可执行文件段表
                NSArray <NSString *>*sectionsArray = [line componentsSeparatedByString:@"\t"];
                if (sectionsArray.count == 4) {
                    NSString *segment = sectionsArray[2];
                    if ([segment isEqualToString:@"__DATA"]) {
                        lastDataAddress = sectionsArray[0];
                        lastDataSize = sectionsArray[1];
                        // 获取第一个__DATA的地址，其偏移量就是 __Text 的大小
                        if (isFirstToData) {
                            // 获取__Text size
                            totalTextSize = [self getSizeFromMAddress:lastDataAddress];
                            isFirstToData = NO;
                            firstDataAddress = lastDataAddress;
                        }
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
    self.totalTextSize = totalTextSize;
    self.totalDataSize = totalDataSize;
    
    _fileNameSymbolMap = fileSymbolMap;
    _frameworkSymbolMap = frameworkSymbolMap;
}

// 通过文件内存地址获取大小
- (NSUInteger)getSizeFromMAddress:(NSString *)mAddress {
    if ([mAddress hasPrefix:@"0x1"]) {
        mAddress = [mAddress stringByReplacingOccurrencesOfString:@"0x1" withString:@"0x0"];
        NSUInteger size = [self getSizeFromHex:mAddress];
        return size;
    } else {
        NSAssert(NO, @"file format error");
        return 0;
    }
}

- (NSUInteger)getSizeFromHex:(NSString *)hex {
    if (![hex hasPrefix:@"0x"]) {
        return 0;
    }
    return strtoul(hex.UTF8String, nil, 16);
}


#pragma make - Helper Methods

- (NSString *)stringWithContentsOfURL:(NSURL *)filePathURL {
    NSString *content = [NSString stringWithContentsOfURL:filePathURL encoding:NSMacOSRomanStringEncoding error:nil];
    return content;
}

- (BOOL)fileExistsAtPathURL:(NSURL *)url {
    return url && [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:nil];
}

- (BOOL)checkContent:(NSString *)content {
    NSRange objsFileTagRange = [content rangeOfString:@"# Object files:"];
    if (objsFileTagRange.length == 0) {
        return NO;
    }
    NSString *subObjsFileSymbolStr = [content substringFromIndex:objsFileTagRange.location + objsFileTagRange.length];
    NSRange symbolsRange = [subObjsFileSymbolStr rangeOfString:@"# Symbols:"];
    if ([content rangeOfString:@"# Path:"].length <= 0||objsFileTagRange.location == NSNotFound||symbolsRange.location == NSNotFound) {
        return NO;
    }
    return YES;
}

- (NSComparisonResult)compare:(NSInteger)size otherSize:(NSInteger)otherSize {
    if(size > otherSize) {
        return NSOrderedAscending;
    } else if (size < otherSize) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (BOOL)displayCondition {
    return self.searchkey.length > 0 || self.whitelistSet.count > 0;
}

- (BOOL)containsString:(NSString *)str {
    return [self containsString:str frameworkName:str];
}

- (BOOL)containsString:(NSString *)str frameworkName:(NSString *)frameworkName {
    if (self.searchkey.length > 0 ) {
        if (self.whitelistSet.count > 0) {
            return [str containsString:self.searchkey] && [self.whitelistSet containsObject:frameworkName];
        } else {
            return [str containsString:self.searchkey];
        }
    } else {
        if (self.whitelistSet.count > 0) {
            return [self.whitelistSet containsObject:frameworkName];
        } else {
            return NO;
        }
    }
}

#pragma make - Setters & Getters

- (NSUInteger)moreThanSize {
    return _moreThanSize == 0 ? 50 : _moreThanSize;
}

- (NSMutableString *)result {
    if (!_result) {
        _result = [[NSMutableString alloc] initWithString:@""];
    }
    return _result;
}

@end
