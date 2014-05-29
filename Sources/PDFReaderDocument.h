//
//	PDFReaderDocument.h
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

#import <Foundation/Foundation.h>

@interface PDFReaderDocument : NSObject <NSObject, NSCoding>

#pragma mark Properties

@property (nonatomic, strong, readonly) NSString *guid;
@property (nonatomic, strong, readonly) NSString *fileName;
@property (nonatomic, strong, readonly) NSDate *fileDate;
@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, strong, readonly) NSNumber *fileSize;

@property (nonatomic, strong, readonly) NSString *password;
@property (nonatomic, strong, readonly) NSMutableIndexSet *bookmarks;

@property (nonatomic, strong, readwrite) NSDate *lastOpen;

@property (nonatomic, strong, readonly) NSNumber *pageCount;
@property (nonatomic, strong, readwrite) NSNumber *pageNumber;


#pragma mark - Class methods

/**
 *  Generate a unique GUID.
 *
 *  @return The generated GUID
 */
+ (NSString *)GUID;

/**
 *  Get the app's documents path, in the sandbox.
 *
 *  @return The documents path
 */
+ (NSString *)documentsPath;

/**
 *  Get the app's sandbox path.
 *
 *  @return The sandbox path
 */
+ (NSString *)applicationPath;

/**
 *  Get the app's support directory.
 *
 *  @return The support directory path
 */
+ (NSString *)applicationSupportPath;

/**
 *  Convert fullFilePath to a relative path within the app's sandbox.
 *
 *  @param fullFilePath The fullFilePath to convert
 *
 *  @return The relative file path
 *
 *  @throws "<PathNotFoundException>" When application path is not found in
 *    the supplied fullFilePath; userInfo will be populated with two keys:
 *    applicationPath and fullFilePath which are both NSString type.
 *
 *  @remark You should wrap calls to this method in a try/catch block.
 */
+ (NSString *)relativeFilePath:(NSString *)fullFilePath;

/**
 *  Generate full path to a PDFReaderDocument archive (located in application
 *    support path) for filename.
 *
 *  @param filename The filename
 *
 *  @return The archive file path.
 *
 *  @throws "<DeprecatedMethod>" When called.
 *
 *  @deprecated Use PDFReaderDocument#archiveFilePathForFileName: instead.
 */
+ (NSString *)archiveFilePath:(NSString *)filename;

/**
 *  Generate full path to a PDFReaderDocument archive (located in application
 *    support path) for filename.
 *
 *  @param filename The filename
 *
 *  @return The archive file path.
 *
 *  @see PDFReaderDocument#applicationSupportPath:
 */
+ (NSString *)archiveFilePathForFileName:(NSString *)filename;

/**
 *  Save the PDFReaderDocument to the archive file path for filename.
 *
 *  @param filename The filename
 *
 *  @return YES on success, otherwise NO
 *
 *  @throws "<DeprecatedMethod>" When called.
 *
 *  @deprecated Use PDFReaderDocument#archiveDocument:withFileName:
 *    instead.
 *
 *  @see PDFReaderDocument#archiveFilePathForFileName
 */

/**
 *  Save the PDFReaderDocument to the archive file path for filename.
 *
 *  @param document The PDFReaderDocument
 *  @param filename The filename
 *
 *  @return YES on success, otherwise NO
 *
 *  @see PDFReaderDocument#archiveFilePathForFileName
 */
+ (BOOL)archiveDocument:(PDFReaderDocument *)document withFileName:(NSString *)
  filename;

/**
 *  Return a new PDFReaderDocument object for the PDF located at filePath.
 *
 *  @param filePath Path to the target PDF
 *  @param phrase   Password phrase (if required)
 *
 *  @return Reference to a PDFReaderDocument object or nil on failure.
 *
 *  @throws "<DeprecatedMethod>" When called.
 *
 *  @deprecated Use PDFReaderDocument#documentWithFilePath:password:
 *    instead.
 */
+ (PDFReaderDocument *)withDocumentFilePath:(NSString *)filePath
                                   password:(NSString *)phrase;

/**
 *  Return a new PDFReaderDocument object for the PDF located at filePath.
 *
 *  @param filePath Path to the target PDF
 *  @param password Password phrase (if required)
 *
 *  @return Reference to a PDFReaderDocument object or nil on failure.
 */
+ (PDFReaderDocument *)documentWithFilePath:(NSString *)filePath
                                   password:(NSString *)password;

/**
 *  Unarchive the PDFReaderDocument representation of the PDF identified by
 *   filename.
 *
 *  @param filename The filename for the target PDF
 *  @param phrase   Password phrase (if required)
 *
 *  @return Reference to a PDFReaderDocument object or nil on failure.
 *
 *  @throws "<DeprecatedMethod>" When called.
 *
 *  @deprecated Use PDFReaderDocument#unarchiveDocumentForFileName:password:
 *    instead.
 */
+ (PDFReaderDocument *)unarchiveFromFileName:(NSString *)filename
                                    password:(NSString *)phrase;

/**
 *  Unarchive the PDFReaderDocument representation of the PDF identified by
 *   filename.
 *
 *  @param filename The filename for the target PDF
 *  @param password Password phrase (if required)
 *
 *  @return Reference to a PDFReaderDocument object or nil on failure.
 */
+ (PDFReaderDocument *)unarchiveDocumentForFileName:(NSString *)filename
                                           password:(NSString *)password;

/**
 *  Checks file at filePath to determine if it's a PDF file by opening the file
 *    and reading its signature.
 *
 *  @param filePath Path to the target PDF
 *
 *  @return YES on success, otherwise NO
 */
+ (BOOL)isPDF:(NSString *)filePath;

#pragma mark - Instance methods

/**
 *  Create a new PDFReaderDocument instance initialized with the PDF file at the
 *    fullFilePath (specifying the passphrase if needed).
 *
 *  @param fullFilePath Path to the target PDF
 *  @param phrase       Password phrase (if required)
 *
 *  @return Reference to a PDFReaderDocument object or nil on failure.
 */
- (instancetype)initWithFilePath:(NSString *)fullFilePath password:(NSString *)phrase;

#pragma mark - Public

/**
 *  Save the PDFReaderDocument to the archive file path for filename.
 *
 *  @param filename The filename
 *
 *  @return YES on success, otherwise NO
 *
 *  @throws "<DeprecatedMethod>" When called.
 *
 *  @deprecated Use PDFReaderDocument#archiveDocument:withFileName:
 *    instead.
 *
 *  @see PDFReaderDocument#archiveFilePathForFileName
 */
- (BOOL)archiveWithFileName:(NSString *)filename;

/**
 *  Save the PDFReaderDocument instance.
 *
 *  @return YES on success, otherwise NO
 */
- (BOOL)saveReaderDocument;

@end
