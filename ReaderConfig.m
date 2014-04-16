//
//	ReaderConfig.m
//
//  Created by Mark Eissler on 4/9/14.
//	Copyright © 2011-2013 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConfig.h"

const BOOL kReaderDefaultBookmarksEnabled = TRUE;
const BOOL kReaderDefaultMailButtonEnabled = TRUE;
const BOOL kReaderDefaultPrintButtonEnabled = TRUE;
const BOOL kReaderDefaultThumbsButtonEnabled = TRUE;
const BOOL kReaderDefaultPreviewThumbEnabled = TRUE;
const BOOL kReaderDefaultPageShadowsEnabled = TRUE;
const BOOL kReaderDefaultRetinaSupportDisabled = FALSE;
const BOOL kReaderDefaultIdleTimerDisabled = FALSE;
const BOOL kReaderDefaultMultimodeDisabled = FALSE;

@implementation ReaderConfig

+ (instancetype)sharedReaderConfig {
  static ReaderConfig *sharedReaderConfig = nil;
  
  // threadsafe init
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedReaderConfig = [[self alloc] initPrivate];
  });
  
  return sharedReaderConfig;
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton"
                                 reason:@"Call +[ReaderConfig sharedStore]"
                               userInfo:nil];
}

- (instancetype)initPrivate {
  self = [super init];
  
  if(self) {
    _bookmarksEnabled = kReaderDefaultBookmarksEnabled;
    _mailButtonEnabled = kReaderDefaultMailButtonEnabled;
    _printButtonEnabled = kReaderDefaultPrintButtonEnabled;
    _thumbsButtonEnabled = kReaderDefaultThumbsButtonEnabled;
    _previewThumbEnabled = kReaderDefaultPreviewThumbEnabled;
    _pageShadowsEnabled = kReaderDefaultPageShadowsEnabled;
    _retinaSupportDisabled = kReaderDefaultRetinaSupportDisabled;
    _idleTimerDisabled = kReaderDefaultIdleTimerDisabled;
    _multimodeDisabled = kReaderDefaultMultimodeDisabled;
  }
  
  return self;
}

@end
