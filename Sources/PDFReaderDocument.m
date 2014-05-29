//
//	PDFReaderDocument.m
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

#import "PDFReaderDocument.h"
#import "CGPDFDocument.h"
#import <fcntl.h>

@interface PDFReaderDocument ()

@property (nonatomic, strong, readwrite) NSString *guid;
@property (nonatomic, strong, readwrite) NSString *fileName;
@property (nonatomic, strong, readwrite) NSDate *fileDate;
@property (nonatomic, strong, readwrite) NSURL *fileURL;
@property (nonatomic, strong, readwrite) NSNumber *fileSize;

@property (nonatomic, strong, readwrite) NSString *password;
@property (nonatomic, strong, readwrite) NSMutableIndexSet *bookmarks;

@property (nonatomic, strong, readwrite) NSNumber *pageCount;

// private methods
- (void)updateProperties;
@end

@implementation PDFReaderDocument

#pragma mark Class Methods

+ (NSString *)GUID
{
  CFUUIDRef cf_uuidRef = CFUUIDCreate(NULL);
  CFStringRef cf_uuidStringRef = CFUUIDCreateString(NULL, cf_uuidRef);
  NSString *uuidString =
    [NSString stringWithString:(__bridge NSString *)cf_uuidStringRef];

  CFRelease(cf_uuidStringRef);
  CFRelease(cf_uuidRef);

  return uuidString;
}

+ (NSString *)documentsPath
{
  NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);

  return [documentsPaths objectAtIndex:0];
}

+ (NSString *)applicationPath
{
  NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(
    NSDocumentDirectory, NSUserDomainMask, YES);

  // Strip "Documents" component
  return [[documentsPaths objectAtIndex:0] stringByDeletingLastPathComponent];
}

+ (NSString *)applicationSupportPath
{
  NSFileManager *fileManager = [NSFileManager new];
  NSURL *pathURL = [fileManager URLForDirectory:NSApplicationSupportDirectory
                                       inDomain:NSUserDomainMask
                              appropriateForURL:nil
                                         create:YES
                                          error:NULL];

  // Path to the application's "~/Library/Application Support" directory
  return [pathURL path];
}

+ (NSString *)relativeFilePath:(NSString *)fullFilePath
{
  NSString *relativePath;
  NSString *applicationPath = [PDFReaderDocument applicationPath];
  NSRange range = [fullFilePath rangeOfString:applicationPath];

  // Ensure that the application path is in the full file path or throw
  if (range.location == NSNotFound)
  {
    NSDictionary *userInfo = [NSDictionary
                              dictionaryWithObjects:@[ applicationPath,
                                                       fullFilePath ]
                                            forKeys:@[ @"applicationPath",
                                                       @"fullFilePath" ]];

    @throw [NSException
            exceptionWithName:@"PathNotFoundException"
                       reason:@"Application path not found in fullFilePath"
                     userInfo:userInfo];
  }

  // Strip out the application path component from the fullFilePath
  relativePath =
      [fullFilePath stringByReplacingCharactersInRange:range withString:@""];

  return relativePath;
}

+ (NSString *)archiveFilePath:(NSString *)filename
{
  @throw [NSException exceptionWithName:@"DeprecatedMethod"
                                 reason:@"Method deprecated, use "
                                         "archiveFilePathForFileName: instead"
                               userInfo:nil];
}

+ (NSString *)archiveFilePathForFileName:(NSString *)filename
{
  NSString *archivePath;
  NSString *applicationSupportPath = [PDFReaderDocument applicationSupportPath];
  NSString *archiveName = [[filename stringByDeletingPathExtension]
      stringByAppendingPathExtension:@"plist"];

  // Append the archive path component to the applicationSupportPath
  //
  // e.g. "{archivePath}/'filename'.plist"
  //
  archivePath =
      [applicationSupportPath stringByAppendingPathComponent:archiveName];

  return archivePath;
}

+ (BOOL)archiveDocument:(PDFReaderDocument *)document withFileName:(NSString *)filename
{
  NSString *archiveFilePath =
  [PDFReaderDocument archiveFilePathForFileName:filename];
  
  BOOL success =
  [NSKeyedArchiver archiveRootObject:document toFile:archiveFilePath];
  
  return success;
}

+ (PDFReaderDocument *)withDocumentFilePath:(NSString *)filePath
                                   password:(NSString *)password {
  @throw
      [NSException exceptionWithName:@"DeprecatedMethod"
                              reason:@"Method deprecated, use "
                                      "documentWithFilePath:password: instead"
                            userInfo:nil];
}

+ (PDFReaderDocument *)documentWithFilePath:(NSString *)filePath
                                   password:(NSString *)password
{
  PDFReaderDocument *document = nil;

  document = [PDFReaderDocument unarchiveDocumentForFileName:filePath
                                                    password:password];

  // Unarchive failed so we create a new PDFReaderDocument object
  if (document == nil)
  {
    document =
      [[PDFReaderDocument alloc] initWithFilePath:filePath password:password];
  }

  return document;
}

+ (PDFReaderDocument *)unarchiveFromFileName:(NSString *)filename
                                    password:(NSString *)phrase
{
  @throw [NSException
      exceptionWithName:@"DeprecatedMethod"
                 reason:@"Method deprecated, use "
                         "unarchiveDocumentForFileName:password: instead"
               userInfo:nil];
}

+ (PDFReaderDocument *)unarchiveDocumentForFileName:(NSString *)filename
                                           password:(NSString *)password
{
  PDFReaderDocument *document = nil;
  NSString *baseFileName = [filename lastPathComponent];
  NSString *archiveFilePath =
    [PDFReaderDocument archiveFilePathForFileName:baseFileName];

  // Unarchive an archived PDFReaderDocument object from its property list, if
  // the archive is invalid an NSInvalidArgumentException will be thrown, in
  // that case we catch it and return nil. Other exceptions are rethrown.
  @try
  {
    document = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveFilePath];

    if ((document != nil) && (password != nil))
    {
      [document setValue:[password copy] forKey:@"password"];
    }
  }
  @catch (NSException *e)
  {
    if ([e.name isEqualToString:@"NSInvalidArgumentException"])
    {
#ifdef DEBUG
      NSLog(@"%s Caught %@: %@", __FUNCTION__, [e name], [e reason]);
#endif
    }
    else
    {
      // rethrow the exception, we don't know what happened!
      @throw;
    }
  }

  return document;
}

+ (BOOL)isPDF:(NSString *)filePath
{
  BOOL isPDF = NO;

  if (!filePath)
  {
    return NO;
  }

  const char *path = [filePath fileSystemRepresentation];

  int fd = open(path, O_RDONLY);
  if (fd > 0)
  {
    // File signature buffer
    const char sig[1024];
    ssize_t len = read(fd, (void *)&sig, sizeof(sig));
    isPDF = (strnstr(sig, "%PDF", len) != NULL);
    
    close(fd);
  }

  return isPDF;
}


#pragma mark - Lifecycle

- (id)initWithFilePath:(NSString *)fullFilePath password:(NSString *)phrase
{
  if (![PDFReaderDocument isPDF:fullFilePath])
  {
    return nil;
  }

  self = [super init];
  if (self)
  {
    _guid = [PDFReaderDocument GUID];
    _password = [phrase copy];
    _bookmarks = [NSMutableIndexSet new];

    // Start on page 1
    _pageNumber = [NSNumber numberWithInteger:1];
    _fileName = [PDFReaderDocument relativeFilePath:fullFilePath];

    CFURLRef docURLRef = (__bridge CFURLRef)[self fileURL];
    CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateX(docURLRef, _password);

    if (thePDFDocRef != NULL)
    {
      NSInteger pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
      _pageCount = [NSNumber numberWithInteger:pageCount];
      CGPDFDocumentRelease(thePDFDocRef);
    } else {
      NSAssert(NO, @"CGPDFDocumentRef == NULL");
    }

    NSFileManager *fileManager = [NSFileManager new];
    NSDictionary *fileAttributes =
      [fileManager attributesOfItemAtPath:fullFilePath error:NULL];

    _lastOpen = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
    _fileDate = [fileAttributes objectForKey:NSFileModificationDate];
    _fileSize = [fileAttributes objectForKey:NSFileSize];

    [self saveReaderDocument];
  }

  return self;
}


#pragma mark - Custom Accessors

- (NSString *)fileName
{
	return [_fileName lastPathComponent];
}

- (NSURL *)fileURL
{
  if (!_fileURL)
  {
    NSString *fullFilePath =
      [[PDFReaderDocument applicationPath] stringByAppendingPathComponent:
     _fileName];

    _fileURL =
      [[NSURL alloc] initFileURLWithPath:fullFilePath isDirectory:NO];
  }

  return _fileURL;
}


#pragma mark - Public

- (BOOL)archiveWithFileName:(NSString *)filename
{
  @throw [NSException exceptionWithName:@"DeprecatedMethod"
                                 reason:@"Method deprecated, use "
          "archiveDocument:withFileName: instead"
                               userInfo:nil];
}

- (BOOL)saveReaderDocument
{
	return [PDFReaderDocument archiveDocument:self withFileName:[self fileName]];
}


#pragma mark - Private

- (void)updateProperties
{
  CFURLRef docURLRef = (__bridge CFURLRef)self.fileURL;
  CGPDFDocumentRef thePDFDocRef = CGPDFDocumentCreateWithURL(docURLRef);
  
  if (thePDFDocRef != NULL)
  {
    NSInteger pageCount = CGPDFDocumentGetNumberOfPages(thePDFDocRef);
    self.pageCount = [NSNumber numberWithInteger:pageCount];
    CGPDFDocumentRelease(thePDFDocRef);
  }
  
  NSString *fullFilePath = [self.fileURL path];
  NSFileManager *fileManager = [NSFileManager new];
  NSDictionary *fileAttributes =
  [fileManager attributesOfItemAtPath:fullFilePath error:NULL];
  
  self.fileDate = [fileAttributes objectForKey:NSFileModificationDate];
  self.fileSize = [fileAttributes objectForKey:NSFileSize];
}


#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:_guid forKey:@"FileGUID"];
	[encoder encodeObject:_fileName forKey:@"FileName"];
	[encoder encodeObject:_fileDate forKey:@"FileDate"];
	[encoder encodeObject:_pageCount forKey:@"PageCount"];
	[encoder encodeObject:_pageNumber forKey:@"PageNumber"];
	[encoder encodeObject:_bookmarks forKey:@"Bookmarks"];
	[encoder encodeObject:_fileSize forKey:@"FileSize"];
	[encoder encodeObject:_lastOpen forKey:@"LastOpen"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self)
  {
    _guid = [decoder decodeObjectForKey:@"FileGUID"];
    _fileName = [decoder decodeObjectForKey:@"FileName"];
    _fileDate = [decoder decodeObjectForKey:@"FileDate"];
    _pageCount = [decoder decodeObjectForKey:@"PageCount"];
    _pageNumber = [decoder decodeObjectForKey:@"PageNumber"];
    _bookmarks = [decoder decodeObjectForKey:@"Bookmarks"];
    _fileSize = [decoder decodeObjectForKey:@"FileSize"];
    _lastOpen = [decoder decodeObjectForKey:@"LastOpen"];

    if (!_guid)
    {
      _guid = [PDFReaderDocument GUID];
    }

    if (!_bookmarks)
    {
      _bookmarks = [_bookmarks mutableCopy];
    } else {
      _bookmarks = [NSMutableIndexSet new];
    }
  }

  return self;
}

@end
