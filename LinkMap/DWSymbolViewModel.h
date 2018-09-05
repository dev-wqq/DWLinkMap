//
//  SymbolViewModel.h
//  LinkMap
//
//  Created by 王启启 on 2018/7/31.
//  Copyright © 2018年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWCalculateHelper.h"
#import "DWBaseModel.h"

typedef NS_ENUM(NSInteger, DWSortedStyle) {
    DWSortedSize = 0,
    DWSortedHistorySize,
    DWSortedDiffSize,
    DWSortedTextSize,
    DWSortedTextDiffSize,
};

@interface DWSymbolViewModel : NSObject

@property (nonatomic, strong) NSMutableDictionary  *fileNameSymbolMap;
@property (nonatomic, strong) NSMutableDictionary  *frameworkSymbolMap;

@property (nonatomic, strong) NSURL    *linkMapFileURL;
@property (nonatomic, strong) NSString *linkMapContent;

@property (nonatomic, strong) NSURL *whitelistURL;
@property (nonatomic, strong) NSSet *whitelistSet;

@property (nonatomic, assign) NSUInteger totalTextSize;
@property (nonatomic, assign) NSUInteger totalDataSize;

@property (nonatomic, assign) BOOL frameworkAnalyze;
@property (nonatomic, assign) BOOL showTop5;
@property (nonatomic, assign) BOOL showMoreThanSize;
@property (nonatomic, assign) BOOL sortedDiffSize;

@property (nonatomic, copy) NSString *searchkey;

@property (nonatomic, strong) NSArray *resultArray;
@property (nonatomic, strong) NSMutableString *result;

/// default
@property (nonatomic, assign) NSUInteger moreThanSize;

@property (nonatomic, strong) DWSymbolViewModel *historyViewModel;

- (void)makeMapFromContent:(NSString *)content;
- (void)makeWhitelistSet:(NSString *)content;

- (BOOL)displayCondition;
- (BOOL)containsString:(NSString *)str;
- (BOOL)containsString:(NSString *)str frameworkName:(NSString *)frameworkName;

- (NSArray *)sortedWithArr:(NSArray *)arr;
- (NSArray *)sortedWithArr:(NSArray *)arr style:(DWSortedStyle)style;

- (void)beginWithCompletionHandler:(void(^)(BOOL result, NSURL *url, NSString *path))handler;

- (void)writeContentWithCompletionHandler:(void(^)(BOOL result, NSURL *url, NSString *path))handler;

@end
