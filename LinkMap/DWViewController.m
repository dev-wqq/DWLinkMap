//
//  ViewController.m
//  LinkMap
//
//  
//  Copyright © 2016 Apple. All rights reserved.
//

#import "DWViewController.h"
#import "DWBaseModel.h"
#import "DWSymbolViewModel.h"
#import "DWCalculateHelper.h"

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
@property (weak) IBOutlet NSButton *moreThanSize;
/// 是否按照差异size排序，默认按照当前版本size降序排序
@property (weak) IBOutlet NSButton *sortedDiffButton;
/// 指示器
@property (weak) IBOutlet NSProgressIndicator *indicator;
///
@property (weak) IBOutlet NSTextField *searchField;
///
@property (weak) IBOutlet NSTextField *dispalyKBField;

@property (weak) IBOutlet NSScrollView *contentView;//分析的内容
@property (unsafe_unretained) IBOutlet NSTextView *contentTextView;

@property (strong) NSURL *historyLinkMapFileURL;
@property (strong) NSURL *currentLinkMapFileURL;
@property (strong) NSURL *whitelistFileURL;

@property (strong) NSString *historyLinkMapContent;
@property (strong) NSString *currentLinkMapContent;

@property (nonatomic, strong) DWSymbolViewModel *historyViewModel;
@property (nonatomic, strong) DWSymbolViewModel *viewModel;

@property (strong) NSMutableString *result;//分析的结果

@end

@implementation DWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicator.hidden = YES;
    
    _contentTextView.editable = NO;
    [[_contentTextView textStorage] setFont:[NSFont fontWithName:@"Monospaced" size:12]];
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
    self.viewModel = [[DWSymbolViewModel alloc] init];
}

- (IBAction)cancaelCurrentLinkMap:(id)sender {
    self.currentPathField.stringValue = @"当前版本路径";
    self.viewModel.linkMapFileURL = nil;
}

- (IBAction)cancelHistoryLinkMap:(id)sender {
    self.historyPathField.stringValue = @"历史版本路径";
    self.historyViewModel.linkMapFileURL = nil;
}

- (IBAction)cancelWhiteList:(id)sender {
    self.whitelistPathField.stringValue = @"分析白名单";
    self.whitelistFileURL = nil;
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
            wself.viewModel.linkMapFileURL  = url;
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

#pragma mark - Analyze Methods

- (IBAction)analyze:(id)sender {
    // 判断路径是否获取成功 or 正确
    BOOL isExistHistory   = [self fileExistsAtPathURL:self.historyViewModel.linkMapFileURL];
    BOOL isExistCurrent   = [self fileExistsAtPathURL:self.viewModel.linkMapFileURL];
    BOOL isExistWhitelist = [self fileExistsAtPathURL:self.whitelistFileURL];
    
    DWAnalyzeType type = DWAnalyzeTypeNone;
    if (isExistCurrent && isExistHistory && isExistWhitelist) {
        type = DWAnalyzeTypeCompareWithWhiteList;
    } else if (isExistCurrent && isExistHistory) {
        type = DWAnalyzeTypeCompare;
    } else if ((isExistHistory || isExistCurrent) && isExistWhitelist) {
        type = DWAnalyzeTypeSingleWithWhiteList;
    } else if (isExistHistory || isExistCurrent) {
        type = DWAnalyzeTypeSingle;
    } else {
        type = DWAnalyzeTypeNone;
    }

    // 负初始值
    BOOL isGroupAnalyze = _groupButton.state == NSControlStateValueOn;
    self.viewModel.frameworkAnalyze = isGroupAnalyze;
    self.viewModel.showTop5 = isGroupAnalyze && _topFiveButton.state == NSControlStateValueOn;
    self.viewModel.showMoreThanSize = isGroupAnalyze && _moreThanSize.state == NSControlStateValueOn;
    self.viewModel.moreThanSize = _dispalyKBField.stringValue.integerValue;
    self.viewModel.searchkey = _searchField.stringValue;
    self.viewModel.sortedDiffSize = _sortedDiffButton.state == NSControlStateValueOn;
    
    // 方法调用
    if (type == DWAnalyzeTypeCompare || type == DWAnalyzeTypeCompareWithWhiteList) {
        [self analyzeCompareVersion:type == DWAnalyzeTypeCompareWithWhiteList];
    } else if (type == DWAnalyzeTypeSingle || type == DWAnalyzeTypeSingleWithWhiteList) {
        [self analyzeSingleVersion:type == DWAnalyzeTypeSingleWithWhiteList];
    } else {
        [self showAlertWithText:@"请选择正确的 LinkMap 文件路径！！！"];
    }
}

#pragma mark - Analyze Single Link Map

- (void)analyzeSingleVersion:(BOOL)isWhitelist {
    
}

#pragma mark - Analyze Both Link Map

- (void)analyzeCompareVersion:(BOOL)isWhitelist {
    [self startAnimation];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *historyContent = [self stringWithContentsOfURL:self.historyViewModel.linkMapFileURL];
        NSString *currentContent = [self stringWithContentsOfURL:self.viewModel.linkMapFileURL];
        
        if (![self checkContent:historyContent]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopAnimation];
                [self showAlertWithText:@"历史版本 LinkMap 文件格式有误"];
            });
            return ;
        }
        if (![self checkContent:currentContent]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopAnimation];
                [self showAlertWithText:@"当前版本 LinkMap 文件格式有误"];
            });
            return ;
        }
        self.historyViewModel.linkMapContent = historyContent;
        self.viewModel.linkMapContent = currentContent;
        self.viewModel.historyViewModel = self.historyViewModel;
        [self.viewModel buildCompareResult];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentTextView.string = self.viewModel.result;
            [self stopAnimation];
        });
    });
}

- (NSMutableDictionary *)symbolMapFromContent:(NSString *)content {
    NSMutableDictionary <NSString *,DWSymbolModel *>*symbolMap = [NSMutableDictionary new];
    NSMutableDictionary <NSString *,DWSymbolModel *>*fileSymbolMap = [NSMutableDictionary new];
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

- (void)buildCompareResultWithSymbols:(NSArray<DWFrameWorkModel *> *)symbols {
    self.result = [@"当前版本\t\t历史版本\t\t版本差异\t\t模块名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    NSUInteger hisTotalSize = 0;
    
    NSString *searchKey = _searchField.stringValue;
    for(DWFrameWorkModel *symbol in symbols) {
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
    
    [_result appendFormat:@"\r\n当前版本总大小: %@\n历史版本总大小: %@\r\n",[DWCalculateHelper calculateSize:totalSize],[DWCalculateHelper calculateSize:hisTotalSize]];
}

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
            [self.viewModel.result writeToFile:content atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }];
}

- (void)appendResultWithSetSymbol:(DWFrameWorkModel *)model {
    [_result appendFormat:@"%@\t\t%@\t\t%@\t\t%@\r\n",model.sizeStr, model.historySizeStr, model.differentSizeStr, model.frameworkName];
}

- (void)appendResultWithSymbol:(DWSymbolModel *)model {
    NSString *size = nil;
    if (model.size / 1000.0 / 1000.0 > 1) {
        size = [NSString stringWithFormat:@"%.2fM", model.size / 1000.0 / 1000.0];
    } else {
        size = [NSString stringWithFormat:@"%.2fK", model.size / 1000.0];
    }
    [_result appendFormat:@"%@\t%@\r\n",size, [[model.file componentsSeparatedByString:@"/"] lastObject]];
}

#pragma make - Animation Methods

- (void)startAnimation {
    self.indicator.hidden = NO;
    [self.indicator startAnimation:self];
}

- (void)stopAnimation {
    self.indicator.hidden = YES;
    [self.indicator stopAnimation:self];
}

#pragma mark - Helper Methods

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

- (void)showAlertWithText:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = text;
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}

@end
