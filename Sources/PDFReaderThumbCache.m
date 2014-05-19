//
//	PDFReaderThumbCache.m
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

#import "PDFReaderThumbCache.h"
#import "PDFReaderThumbQueue.h"
#import "PDFReaderThumbFetch.h"
#import "PDFReaderThumbView.h"

@implementation PDFReaderThumbCache
{
	NSCache *thumbCache;
}

#pragma mark Constants

#define CACHE_SIZE 2097152

#pragma mark PDFReaderThumbCache class methods

+ (PDFReaderThumbCache *)sharedInstance
{
	static dispatch_once_t predicate = 0;

	static PDFReaderThumbCache *object = nil; // Object

	dispatch_once(&predicate, ^{ object = [self new]; });

	return object; // PDFReaderThumbCache singleton
}

+ (NSString *)appCachesPath
{
	static dispatch_once_t predicate = 0;

	static NSString *theCachesPath = nil; // Application caches path string

	dispatch_once(&predicate, // Save a copy of the application caches path the first time it is needed
	^{
		NSArray *cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

		theCachesPath = [[cachesPaths objectAtIndex:0] copy]; // Keep a copy for later abusage
	});

	return theCachesPath;
}

+ (NSString *)thumbCachePathForGUID:(NSString *)guid
{
	NSString *cachesPath = [PDFReaderThumbCache appCachesPath]; // Caches path

	return [cachesPath stringByAppendingPathComponent:guid]; // Append GUID
}

+ (void)createThumbCacheWithGUID:(NSString *)guid
{
	NSFileManager *fileManager = [NSFileManager new]; // File manager instance

	NSString *cachePath = [PDFReaderThumbCache thumbCachePathForGUID:guid]; // Thumb cache path

	[fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:NULL];
}

+ (void)removeThumbCacheWithGUID:(NSString *)guid
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
	^{
		NSFileManager *fileManager = [NSFileManager new]; // File manager instance

		NSString *cachePath = [PDFReaderThumbCache thumbCachePathForGUID:guid]; // Thumb cache path

		[fileManager removeItemAtPath:cachePath error:NULL]; // Remove thumb cache directory
	});
}

+ (void)touchThumbCacheWithGUID:(NSString *)guid
{
	NSFileManager *fileManager = [NSFileManager new]; // File manager instance

	NSString *cachePath = [PDFReaderThumbCache thumbCachePathForGUID:guid]; // Thumb cache path

	NSDictionary *attributes = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];

	[fileManager setAttributes:attributes ofItemAtPath:cachePath error:NULL]; // New modification date
}

+ (void)purgeThumbCachesOlderThan:(NSTimeInterval)age
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
	^{
		NSDate *now = [NSDate date]; // Right about now time

		NSString *cachesPath = [PDFReaderThumbCache appCachesPath]; // Caches path

		NSFileManager *fileManager = [NSFileManager new]; // File manager instance

		NSArray *cachesList = [fileManager contentsOfDirectoryAtPath:cachesPath error:NULL];

		if (cachesList != nil) // Process caches directory contents
		{
			for (NSString *cacheName in cachesList) // Enumerate directory contents
			{
				if (cacheName.length == 36) // This is a very hacky cache ident kludge
				{
					NSString *cachePath = [cachesPath stringByAppendingPathComponent:cacheName];

					NSDictionary *attributes = [fileManager attributesOfItemAtPath:cachePath error:NULL];

					NSDate *cacheDate = [attributes objectForKey:NSFileModificationDate]; // Cache date

					NSTimeInterval seconds = [now timeIntervalSinceDate:cacheDate]; // Cache age

					if (seconds > age) // Older than so remove the thumb cache
					{
						[fileManager removeItemAtPath:cachePath error:NULL];

						#ifdef DEBUG
							NSLog(@"%s purged %@", __FUNCTION__, cacheName);
						#endif
					}
				}
			}
		}
	});
}

#pragma mark PDFReaderThumbCache instance methods

- (id)init
{
	if ((self = [super init])) // Initialize
	{
		thumbCache = [NSCache new]; // Cache

		[thumbCache setName:@"PDFReaderThumbCache"];

		[thumbCache setTotalCostLimit:CACHE_SIZE];
	}

	return self;
}

- (id)thumbRequest:(PDFReaderThumbRequest *)request priority:(BOOL)priority
{
	@synchronized(thumbCache) // Mutex lock
	{
		id object = [thumbCache objectForKey:request.cacheKey];

		if (object == nil) // Thumb object does not yet exist in the cache
		{
			object = [NSNull null]; // Return an NSNull thumb placeholder object

			[thumbCache setObject:object forKey:request.cacheKey cost:2]; // Cache the placeholder object

			PDFReaderThumbFetch *thumbFetch = [[PDFReaderThumbFetch alloc] initWithRequest:request]; // Create a thumb fetch operation

			[thumbFetch setQueuePriority:(priority ? NSOperationQueuePriorityNormal : NSOperationQueuePriorityLow)]; // Queue priority

			request.thumbView.operation = thumbFetch; [thumbFetch setThreadPriority:(priority ? 0.55 : 0.35)]; // Thread priority

			[[PDFReaderThumbQueue sharedInstance] addLoadOperation:thumbFetch]; // Queue the operation
		}

		return object; // NSNull or UIImage
	}
}

- (void)setObject:(UIImage *)image forKey:(NSString *)key
{
	@synchronized(thumbCache) // Mutex lock
	{
		NSUInteger bytes = (image.size.width * image.size.height * 4.0f);

		[thumbCache setObject:image forKey:key cost:bytes]; // Cache image
	}
}

- (void)removeObjectForKey:(NSString *)key
{
	@synchronized(thumbCache) // Mutex lock
	{
		[thumbCache removeObjectForKey:key];
	}
}

- (void)removeNullForKey:(NSString *)key
{
	@synchronized(thumbCache) // Mutex lock
	{
		id object = [thumbCache objectForKey:key];

		if ([object isMemberOfClass:[NSNull class]])
		{
			[thumbCache removeObjectForKey:key];
		}
	}
}

- (void)removeAllObjects
{
	@synchronized(thumbCache) // Mutex lock
	{
		[thumbCache removeAllObjects];
	}
}

@end
