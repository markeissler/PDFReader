//
//	PDFReaderConfig.m
//
//  Copyright (C) 2011-2013 Julius Oklamcak. All rights reserved.
//  Portions (C) 2014 Mark Eissler. All rights reserved.
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

#import "PDFReaderConfig.h"

const BOOL kPDFReaderDefaultBookmarksEnabled = TRUE;
const BOOL kPDFReaderDefaultMailButtonEnabled = TRUE;
const BOOL kPDFReaderDefaultPrintButtonEnabled = TRUE;
const BOOL kPDFReaderDefaultThumbsButtonEnabled = TRUE;
const BOOL kPDFReaderDefaultPreviewThumbEnabled = TRUE;
const BOOL kPDFReaderDefaultPageShadowsEnabled = TRUE;
const BOOL kPDFReaderDefaultRetinaSupportDisabled = FALSE;
const BOOL kPDFReaderDefaultIdleTimerDisabled = FALSE;
const BOOL kPDFReaderDefaultMultimodeDisabled = FALSE;

@implementation PDFReaderConfig

+ (instancetype)sharedConfig {
  static PDFReaderConfig *sharedConfig = nil;

  // threadsafe init
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedConfig = [[self alloc] initPrivate];
  });

  return sharedConfig;
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton"
                                 reason:@"Call +[PDFReaderConfig sharedStore]"
                               userInfo:nil];
}

- (instancetype)initPrivate {
  self = [super init];

  if(self) {
    _bookmarksEnabled = kPDFReaderDefaultBookmarksEnabled;
    _mailButtonEnabled = kPDFReaderDefaultMailButtonEnabled;
    _printButtonEnabled = kPDFReaderDefaultPrintButtonEnabled;
    _thumbsButtonEnabled = kPDFReaderDefaultThumbsButtonEnabled;
    _previewThumbEnabled = kPDFReaderDefaultPreviewThumbEnabled;
    _pageShadowsEnabled = kPDFReaderDefaultPageShadowsEnabled;
    _retinaSupportDisabled = kPDFReaderDefaultRetinaSupportDisabled;
    _idleTimerDisabled = kPDFReaderDefaultIdleTimerDisabled;
    _multimodeDisabled = kPDFReaderDefaultMultimodeDisabled;
  }

  return self;
}

@end
