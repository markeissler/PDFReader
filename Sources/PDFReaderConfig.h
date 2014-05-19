//
//	PDFReaderConfig.h
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

#if !__has_feature(objc_arc)
  #error ARC (-fobjc-arc) is required to build this code.
#endif

#import <Foundation/Foundation.h>

/**
 *  @memberof PDFReaderConfig
 *  Default value for bookmarksEnabled: TRUE
 */
extern const BOOL kPDFReaderDefaultBookmarksEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for mailButtonEnabled: TRUE
 */
extern const BOOL kPDFReaderDefaultMailButtonEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for printButtonEnabled: TRUE
 */
extern const BOOL kPDFReaderDefaultPrintButtonEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for thumbsButtonEnable: TRUE
 */
extern const BOOL kPDFReaderDefaultThumbsButtonEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for previewThumbEnabled: TRUE
 */
extern const BOOL kPDFReaderDefaultPreviewThumbEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for pageShadowsEnabled: TRUE
 */
extern const BOOL kPDFReaderDefaultPageShadowsEnabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for retinaSupportDisabled: FALSE
 */
extern const BOOL kPDFReaderDefaultRetinaSupportDisabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for idleTimerDisabled: FALSE
 */
extern const BOOL kPDFReaderDefaultIdleTimerDisabled;

/**
 *  @memberof PDFReaderConfig
 *  Default value for multimodeDisabled: FALSE
 */
extern const BOOL kPDFReaderDefaultMultimodeDisabled;

/**
 *  `PDFReaderConfig` is a singleton class that manages PDFReader global
 *  configuration parameters.
 */
@interface PDFReaderConfig : NSObject

/**
 *  Enable/disable bookmark support.
 *
 *  @see kPDFReaderDefaultBookmarksEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isBookmarksEnabled)
    BOOL bookmarksEnabled;

/**
 *  Enable addition of mail button to toolbar.
 *
 *  @note
 *  Only enabled if the device is properly configured for email support.
 *
 *  @see kPDFReaderDefaultMailButtonEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isMailButtonEnabled)
    BOOL mailButtonEnabled;

/**
 *  Enable addition of print button to toolbar.
 *
 *  @note
 *  Only enabled if printing is supported and available on the device.
 *
 *  @see kPDFReaderDefaultPrintButtonEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isPrintButtonEnabled)
    BOOL printButtonEnabled;

/**
 *  Enable addition of thumbnails button to toolbar.
 *
 *  @see kPDFReaderDefaultThumbsButtonEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained,
           getter=isThumbsButtonEnabled) BOOL thumbsButtonEnabled;
/**
 *  Enable display of medium resolution page thumbnail is displayed before the
 *  CATiledLayer starts to render the PDF page.
 *
 *  @see kPDFReaderDefaultPreviewThumbEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained,
           getter=isPreviewThumbEnabled) BOOL previewThumbEnabled;

/**
 *  Enable generation of page shadow around each page and inset page content
 *  by a couple of extra points
 *
 *  @see kPDFReaderDefaultPageShadowsEnabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isPageShadowsEnabled)
    BOOL pageShadowsEnabled;

/**
 *  When TRUE, sets the CATiledLayer contentScale to 1.0f. This effectively
 *  disables retina support and results in non-retina device rendering speeds on
 *  retina display devices at the loss of retina display quality.
 *
 *  @see kPDFReaderDefaultRetinaSupportDisabled
 */
@property (nonatomic, readwrite, unsafe_unretained,
           getter=isRetinaSupportDisabled) BOOL retinaSupportDisabled;

/**
 *  When TRUE, the iOS idle timer is disabled while viewing a document (beware
 *  of battery drain).
 *
 *  @see kPDFReaderDefaultIdleTimerDisabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isIdleTimerDisabled)
    BOOL idleTimerDisabled;

/**
 *  Disable addition of Done button to toolbar.
 *
 *  @note
 *  The -dismissReaderViewController: delegate method is messaged when button is
 *  tapped.
 *
 *  @see kPDFReaderDefaultMultimodeDisabled
 */
@property (nonatomic, readwrite, unsafe_unretained, getter=isMultimodeDisabled)
    BOOL multimodeDisabled;

/**
 * -----------------------------------------------------------------------------
 * @name Accessing the shared PDFReaderConfig Instance
 * -----------------------------------------------------------------------------
 */

/**
 * Returns the shared `PDFReaderConfig` instance, creating it if necessary.
 *
 * @return The shared `PDFReaderConfig` instance.
 */
+ (instancetype)sharedConfig;


@end
