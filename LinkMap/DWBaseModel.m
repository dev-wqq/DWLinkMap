//
//  SymbolModel.m
//  LinkMap
//
//  
//  Copyright © 2016 Apple. All rights reserved.
//

#import "DWBaseModel.h"
#import "DWCalculateHelper.h"

@implementation DWBaseModel

- (NSString *)sizeStr {
    return [DWCalculateHelper calculateSize:self.size];
}

- (NSString *)historySizeStr {
    return [DWCalculateHelper calculateSize:self.historySize];
}

- (NSInteger)differentSize {
    return self.size - self.historySize;
}

- (NSString *)differentSizeStr {
    return [DWCalculateHelper calculateDiffSize:self.differentSize];
}

@end

@interface DWSymbolModel ()

/// 文件名称 库名称(文件名称.o)
@property (nonatomic, copy) NSString *fileName;
/// 库名称
@property (nonatomic, copy) NSString *frameworkName;

@end

@implementation DWSymbolModel

- (void)setFile:(NSString *)file {
    _fileName = nil;
    _frameworkName = nil;
    _file = file;
}

- (NSString *)fileName {
    if (!_fileName) {
        NSString *name = [[self.file componentsSeparatedByString:@"/"] lastObject];
        if (name) {
            _fileName = name;
        } else {
            _fileName = _file;
        }
        
    }
    return _fileName;
}

- (NSString *)frameworkName {
    if (!_frameworkName) {
        if ([self.fileName hasSuffix:@")"] &&
            [self.fileName containsString:@"("]) {
            NSRange range = [self.fileName rangeOfString:@"("];
            NSString *component = [self.fileName substringToIndex:range.location];
            _frameworkName = component;
        } else {
            _frameworkName = self.fileName;
        }
    }
    return _frameworkName;
}

@end

@implementation DWFrameWorkModel

@end
