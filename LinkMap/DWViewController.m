//
//  ViewController.m
//  LinkMap
//
//  Created by Suteki(67111677@qq.com) on 4/8/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "DWViewController.h"
#import "SymbolModel.h"
#import "DWSymbolViewModel.h"

typedef NS_ENUM(NSInteger, DWAnalyzeType) {
    DWAnalyzeTypeNone   = 0,
    DWAnalyzeTypeSingle = 1,
    DWAnalyzeTypeSingleWithWhiteList  = 2,
    DWAnalyzeTypeCompare = 3,
    DWAnalyzeTypeCompareWithWhiteList = 4,
};

@interface DWViewController()

/// 历史版本选择的文件路径
@property (weak) IBOutlet NSTextField *historyPathField;
/// 当前版本选择的文件路径
@property (weak) IBOutlet NSTextField *currentPathField;
/// 白名单选择的文件路径

@property (weak) IBOutlet NSTextField *whitelistPathField;

/// 模块解析
@property (weak) IBOutlet NSButton *groupButton;
/// 显示每个模块top5的文件
@property (weak) IBOutlet NSButton *topFiveButton;
/// 显示大于100KB
@property (weak) IBOutlet NSButton *moreThan100KB;
/// 显示大于50KB
@property (weak) IBOutlet NSButton *moreThan50KB;

/// 对比size的差异
@property (weak) IBOutlet NSButton *sizeDiffButton;
/// 对比文件的差异
@property (strong) IBOutlet NSView *fileDiffButton;

@property (weak) IBOutlet NSProgressIndicator *indicator;//指示器
@property (weak) IBOutlet NSTextField *searchField;

@property (weak) IBOutlet NSScrollView *contentView;//分析的内容
@property (unsafe_unretained) IBOutlet NSTextView *contentTextView;


@property (strong) NSURL *historyLinkMapFileURL;
@property (strong) NSURL *currentLinkMapFileURL;
@property (strong) NSURL *whitelistFileURL;

@property (strong) NSString *historyLinkMapContent;
@property (strong) NSString *currentLinkMapContent;

@property (nonatomic, strong) DWSymbolViewModel *historyViewModel;
@property (nonatomic, strong) DWSymbolViewModel *currentViewModel;

@property (strong) NSMutableString *result;//分析的结果

@end

@implementation DWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicator.hidden = YES;
    
    _contentTextView.editable = NO;
    
    _contentTextView.string = @"使用方式：\n\
    1.在XCode中开启编译选项Write Link Map File \n\
    XCode -> Project -> Build Settings -> 把Write Link Map File选项设为yes，并指定好linkMap的存储位置 \n\
    2.工程编译完成后，在编译目录里找到Link Map文件（txt类型） \n\
    默认的文件地址：~/Library/Developer/Xcode/DerivedData/XXX-xxxxxxxxxxxxx/Build/Intermediates/XXX.build/Debug-iphoneos/XXX.build/ \n\
    3.回到本应用，点击“选择文件”，打开Link Map文件  \n\
    4.点击“开始”，解析Link Map文件 \n\
    5.点击“输出文件”，得到解析后的Link Map文件 \n\
    6. * 输入目标文件的关键字(例如：libIM)，然后点击“开始”。实现搜索功能 \n\
    7. * 勾选“分组解析”，然后点击“开始”。实现对不同库的目标文件进行分组";
    
    self.historyViewModel = [[DWSymbolViewModel alloc] init];
    self.currentViewModel = [[DWSymbolViewModel alloc] init];
}

#pragma make - Choose File Path

- (IBAction)chooseHistoryVersionFilePath:(id)sender {
    __weak typeof(self) wself = self;
    [self beginWithCompletionHandler:^(BOOL result, NSURL *url, NSString *path) {
        if (result) {
            wself.historyPathField.stringValue = path;
            wself.historyViewModel.linkMapFileURL = url;
        }
    }];
}

- (IBAction)chooseCurrentVersionFilePath:(id)sender {
    __weak typeof(self) wself = self;
    [self beginWithCompletionHandler:^(BOOL result, NSURL *url, NSString *path) {
        if (result) {
            wself.currentPathField.stringValue = path;
            wself.currentViewModel.linkMapFileURL  = url;
        }
    }];
}

- (IBAction)chooseWhitelistFilePath:(id)sender {
    __weak typeof(self) wself = self;
    [self beginWithCompletionHandler:^(BOOL result, NSURL *url, NSString *path) {
        if (result) {
            wself.whitelistPathField.stringValue = path;
            wself.whitelistFileURL = url;
        }
    }];
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

- (IBAction)analyze:(id)sender {
    BOOL isExistHistory   = YES;
    BOOL isExistCurrent   = YES;
    BOOL isExistWhitelist = YES;
    if (!self.historyViewModel.linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[self.historyViewModel.linkMapFileURL path] isDirectory:nil]) {
        isExistHistory = NO;
    }
    
    if (!self.currentViewModel.linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[self.currentViewModel.linkMapFileURL path] isDirectory:nil]) {
        isExistCurrent = NO;
    }
    
    if (!_whitelistFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[_whitelistFileURL path] isDirectory:nil]) {
        isExistWhitelist = NO;
    }
    
    DWAnalyzeType type = DWAnalyzeTypeNone;
    if (isExistHistory && isExistHistory && isExistWhitelist) {
        type = DWAnalyzeTypeCompareWithWhiteList;
    } else if (isExistHistory && isExistHistory) {
        type = DWAnalyzeTypeCompare;
    } else if ((isExistHistory || isExistCurrent) && isExistWhitelist) {
        type = DWAnalyzeTypeSingleWithWhiteList;
    } else if (isExistHistory || isExistCurrent) {
        type = DWAnalyzeTypeSingle;
    } else {
        type = DWAnalyzeTypeNone;
    }
    
    if (type == DWAnalyzeTypeNone) {
        [self showAlertWithText:@"请选择正确的 LinkMap 文件路径！！！"];
        return;
    } else if (type == DWAnalyzeTypeCompare || type == DWAnalyzeTypeCompareWithWhiteList) {
        [self analyzeCompareVersion:type == DWAnalyzeTypeCompareWithWhiteList];
    }
}

- (void)analyzeCompareVersion:(BOOL)isWhitelist {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *historyContent = [self stringWithURL:self.historyViewModel.linkMapFileURL];
        NSString *currentContent = [self stringWithURL:self.currentViewModel.linkMapFileURL];
        
        if (![self checkContent:historyContent]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithText:@"历史版本 LinkMap 文件格式有误"];
            });
            return ;
        }
        if (![self checkContent:currentContent]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithText:@"当前版本 LinkMap 文件格式有误"];
            });
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.indicator.hidden = NO;
            [self.indicator startAnimation:self];
        });
        self.historyViewModel.linkMapContent = historyContent;
        self.currentViewModel.linkMapContent = currentContent;

        [self combineHistoryRecords];
        
        NSArray <DWSymbolSetModel *>* sets = [self.currentViewModel sortSetSymbols];
        
        [self buildCompareResultWithSymbols:sets];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentTextView.string = _result;
            self.indicator.hidden = YES;
            [self.indicator stopAnimation:self];

        });
    });
}
                   
- (NSString *)stringWithURL:(NSURL *)filePathURL {
    NSString *content = [NSString stringWithContentsOfURL:filePathURL
                                                        encoding:NSMacOSRomanStringEncoding
                                                           error:nil];
    return content;
}

- (void)combineHistoryRecords {
    NSMutableDictionary *temp = self.historyViewModel.frameworkSymbolMap.mutableCopy;
    for (NSString *key in self.currentViewModel.frameworkSymbolMap.allKeys) {
        DWSymbolSetModel *curSetModel = self.currentViewModel.frameworkSymbolMap[key];
        DWSymbolSetModel *hisSetModel = self.historyViewModel.frameworkSymbolMap[key];
        
        curSetModel.historySize = hisSetModel.size;
        curSetModel.historySubMap = hisSetModel.subMap;
        if (!hisSetModel) {
            curSetModel.frameworkName = [NSString stringWithFormat:@"新增 %@",curSetModel.frameworkName];
        }
        
        [temp removeObjectForKey:key];
    }
    if (temp.allKeys.count > 0) {
        for (NSString *key in temp.allKeys) {
            DWSymbolSetModel *hisSetModel = temp[key];
            DWSymbolSetModel *setModel = [[DWSymbolSetModel alloc] init];
            setModel.subMap = hisSetModel.subMap;
            setModel.historySubMap = hisSetModel.historySubMap;
            setModel.historySize = hisSetModel.size;
            setModel.frameworkName = [NSString stringWithFormat:@"已删除 %@",hisSetModel.frameworkName];
            self.currentViewModel.frameworkSymbolMap[hisSetModel.frameworkName] = setModel;
        }
    }
}

- (NSMutableDictionary *)symbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,SymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,SymbolModel *>*fileSymbolMap = [NSMutableDictionary new];
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
                        if(symbol) {
                            symbol.size += size;
                        }
                    }
                }
            }
        }
    }
    return fileSymbolMap;
}

- (NSArray *)sortSymbols:(NSArray *)symbols {
    NSArray *sortedSymbols = [symbols sortedArrayUsingComparator:^NSComparisonResult(SymbolModel *  _Nonnull obj1, SymbolModel *  _Nonnull obj2) {
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


- (void)buildCompareResultWithSymbols:(NSArray<DWSymbolSetModel *> *)symbols {
    self.result = [@"当前版本\t\t历史版本\t\t版本差异\t\t模块名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    NSString *searchKey = _searchField.stringValue;
    for(DWSymbolSetModel *symbol in symbols) {
        if (searchKey.length > 0) {
            if ([symbol.frameworkName containsString:searchKey]) {
                [self appendResultWithSetSymbol:symbol];
                totalSize += symbol.size;
                hisTotalSize += symbol.historySize;
            }
        } else {
            [self appendResultWithSetSymbol:symbol];
            totalSize += symbol.size;
            hisTotalSize += symbol.historySize;
        }
    }
    
    [_result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@\r\n",[self getSize:totalSize],[self getSize:hisTotalSize]];
}


//- (void)buildCombinationResultWithSymbols:(NSArray *)symbols {
//    self.result = [@"库大小\t库名称\r\n\r\n" mutableCopy];
//    NSUInteger totalSize = 0;
//
//    NSMutableDictionary *combinationMap = [[NSMutableDictionary alloc] init];
//
//    for(SymbolModel *symbol in symbols) {
//        NSString *name = [[symbol.file componentsSeparatedByString:@"/"] lastObject];
//        if ([name hasSuffix:@")"] &&
//            [name containsString:@"("]) {
//            NSRange range = [name rangeOfString:@"("];
//            NSString *component = [name substringToIndex:range.location];
//
//            SymbolModel *combinationSymbol = [combinationMap objectForKey:component];
//            if (!combinationSymbol) {
//                combinationSymbol = [[SymbolModel alloc] init];
//                [combinationMap setObject:combinationSymbol forKey:component];
//            }
//
//            combinationSymbol.size += symbol.size;
//            combinationSymbol.file = component;
//        } else {
//            // symbol可能来自app本身的目标文件或者系统的动态库，在最后的结果中一起显示
//            [combinationMap setObject:symbol forKey:symbol.file];
//        }
//    }
//
//    NSArray <SymbolModel *>*combinationSymbols = [combinationMap allValues];
//
//    NSArray *sortedSymbols = [self sortSymbols:combinationSymbols];
//
//    NSString *searchKey = _searchField.stringValue;
//
//    for(SymbolModel *symbol in sortedSymbols) {
//        if (searchKey.length > 0) {
//            if ([symbol.file containsString:searchKey]) {
//                [self appendResultWithSymbol:symbol];
//                totalSize += symbol.size;
//            }
//        } else {
//            [self appendResultWithSymbol:symbol];
//            totalSize += symbol.size;
//        }
//    }
//
//    [_result appendFormat:@"\r\n总大小: %.2fM\r\n",(totalSize/1000.0/1000.0)];
//}

- (IBAction)ouputFile:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setResolvesAliases:NO];
    [panel setCanChooseFiles:NO];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            NSMutableString *content =[[NSMutableString alloc]initWithCapacity:0];
            [content appendString:[theDoc path]];
            [content appendString:@"/linkMap.txt"];
            [_result writeToFile:content atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }];
}

- (NSString *)getSize:(NSInteger)size {
    NSString *sizeStr = nil;
    NSInteger temp = size / 1000.0 / 1000.0;
    if (temp >= 1.0 || temp <= -1.0) {
        sizeStr = [NSString stringWithFormat:@"%.2fM", size / 1000.0 / 1000.0];
    } else {
        sizeStr = [NSString stringWithFormat:@"%.2fK", size / 1000.0];
    }
    return sizeStr;
}

- (NSString *)getDiffSize:(NSInteger)size {
    NSString *sizeStr = nil;
    NSInteger temp = size / 1000.0 / 1000.0;
    NSString *addOrReduce = size > 0 ? @"+" : @"";
    if (temp >= 1.0 || temp <= -1.0) {
        sizeStr = [NSString stringWithFormat:@"%@%.2fM", addOrReduce,size / 1000.0 / 1000.0];
    } else {
        sizeStr = [NSString stringWithFormat:@"%@%.2fK", addOrReduce, size / 1000.0];
    }
    return sizeStr;
}

- (void)appendResultWithSetSymbol:(DWSymbolSetModel *)model {
    NSString *size = [self getSize:model.size];
    NSString *historySize = [self getSize:model.historySize];
    NSString *diffSize = [self getDiffSize:model.size - model.historySize];
    
    [_result appendFormat:@"%@\t\t%@\t\t%@\t\t%@\r\n",size, historySize, diffSize, model.frameworkName];
}

- (void)appendResultWithSymbol:(SymbolModel *)model {
    NSString *size = nil;
    if (model.size / 1000.0 / 1000.0 > 1) {
        size = [NSString stringWithFormat:@"%.2fM", model.size / 1000.0 / 1000.0];
    } else {
        size = [NSString stringWithFormat:@"%.2fK", model.size / 1000.0];
    }
    [_result appendFormat:@"%@\t%@\r\n",size, [[model.file componentsSeparatedByString:@"/"] lastObject]];
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

- (void)showAlertWithText:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = text;
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}

@end
