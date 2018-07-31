//
//  SymbolModel.m
//  LinkMap
//
//  Created by Suteki(67111677@qq.com) on 4/8/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "SymbolModel.h"

@interface SymbolModel ()

@end

@implementation SymbolModel

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

@implementation DWSymbolSetModel

@end
