//
//	PDFReaderViewController.h
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

#import "PDFReaderDocument.h"

#pragma mark PDFViewController Constants

/**
 *  @memberof PDFReaderViewController
 *  Default value for currentViews "window" buffer.
 */
extern const NSInteger kPDFReaderDefaultPagingViews;

/**
 *  @memberof PDFReaderViewController
 *  Default value for status bar height.
 */
extern const CGFloat kPDFReaderDefaultStatusBarHeight;

/**
 *  @memberof PDFReaderViewController
 *  Default value for toolbar height.
 */
extern const CGFloat kPDFReaderDefaultToolBarHeight;

/**
 *  @memberof PDFReaderViewController
 *  Default value for pagebar height.
 */
extern const CGFloat kPDFReaderDefaultPageBarHeight;

/**
 *  @memberof PDFReaderViewController
 *  Default value for tap area target size.
 */
extern const CGFloat kPDFReaderDefaultTapAreaSize;


#pragma mark -
#pragma mark PDFViewController Class

@class PDFReaderViewController;

@protocol PDFReaderViewControllerDelegate <NSObject>

@optional // Delegate protocols

- (void)dismissReaderViewController:(PDFReaderViewController *)viewController;

@end

@interface PDFReaderViewController : UIViewController

@property (nonatomic, weak, readwrite) id <PDFReaderViewControllerDelegate> delegate;

/**
 *  Initializes and returns a newly allocated PDFReaderViewController object.
 *
 *  @param object Reference to an initialized PDFReaderDocument
 *
 *  @return Initialized class instance or nil on failure
 *
 *  @throws "<Missing arguments>" When object is nil
 *  @throws "<Wrong type>" When object is not a reference to a PDFReaderDocument
 *    object
 *
 *  @remark Designated initializer.
 */
- (instancetype)initWithReaderDocument:(PDFReaderDocument *)object;

/**
 *  Update the PDFReader's ScrollView width to match document length, or match
 *    contentView window buffer length.
 *
 *  @remark You should call this method if you override in a subclass.
 */
- (void)updateScrollViewContentSize;

/**
 *  Update the viewRect for each contentView in the PDFReader's ScrollView, and
 *    set the contentOffset to the offset of the contentView for the currently
 *    selected page.
 */
- (void)updateScrollViewContentViews;

/**
 *  Update bookmark state for each page in the PDFReaderDocument's bookmarks 
 *    list.
 */
- (void)updateToolbarBookmarkIcon;

/**
 *  Update the PDFReader's ScrollView to display the page specified.
 *
 *  @param page The page number
 */
- (void)showDocumentPage:(NSInteger)page;

/**
 *  Display the PDFReaderDocument, scrolling to its currently selected page and
 *    updating the lastOpen date.
 *
 *  @param object Unused
 *
 *  @see PDFReaderViewController#initWithReaderDocument:
 */
- (void)showDocument:(id)object;

@end
