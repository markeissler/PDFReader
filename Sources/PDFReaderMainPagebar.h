//
//	PDFReaderMainPagebar.h
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

#import <UIKit/UIKit.h>

#import "PDFReaderThumbView.h"

@class PDFReaderMainPagebar;
@class PDFReaderTrackControl;
@class PDFReaderPagebarThumb;
@class PDFReaderDocument;

@protocol PDFReaderMainPagebarDelegate <NSObject>

@required // Delegate protocols

- (void)pagebar:(PDFReaderMainPagebar *)pagebar gotoPage:(NSInteger)page;

@end

@interface PDFReaderMainPagebar : UIView

@property (nonatomic, weak, readwrite) id <PDFReaderMainPagebarDelegate> delegate;

- (id)initWithFrame:(CGRect)frame document:(PDFReaderDocument *)object;

- (void)updatePagebar;

- (void)hidePagebar;
- (void)showPagebar;

@end

#pragma mark -

//
//	PDFReaderTrackControl class interface
//

@interface PDFReaderTrackControl : UIControl

@property (nonatomic, assign, readonly) CGFloat value;

@end

#pragma mark -

//
//	PDFReaderPagebarThumb class interface
//

@interface PDFReaderPagebarThumb : PDFReaderThumbView

- (id)initWithFrame:(CGRect)frame small:(BOOL)small;

@end

#pragma mark -

//
//	PDFReaderPagebarShadow class interface
//

@interface PDFReaderPagebarShadow : UIView

@end
