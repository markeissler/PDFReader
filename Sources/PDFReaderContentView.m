//
//	PDFReaderContentView.m
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
#import "PDFReaderContentView.h"
#import "PDFReaderContentPage.h"
#import "PDFReaderThumbCache.h"

#import <QuartzCore/QuartzCore.h>

@interface PDFReaderContentView () <UIScrollViewDelegate>
@property (nonatomic, readwrite, unsafe_unretained) float insetMargin;
@property (nonatomic, readwrite, unsafe_unretained) float pageThumbLarge;
@property (nonatomic, readwrite, unsafe_unretained) float pageThumbSmall;
@property (nonatomic, readwrite, unsafe_unretained) float zoomFactor;
@property (nonatomic, readwrite, unsafe_unretained) float zoomMaximum;
@end

@implementation PDFReaderContentView
{
	PDFReaderContentPage *theContentView;

	PDFReaderContentThumb *theThumbView;

	UIView *theContainerView;
}

static void *PDFReaderContentViewContext = &PDFReaderContentViewContext;

#pragma mark Properties

// FIXME: we should use underscore consistently for data members and then get
// rid of these @synthesize statements.
@synthesize message;
@synthesize contentInset = _contentInset;
@synthesize pageThumbLarge = _pageThumbLarge;
@synthesize pageThumbSmall = _pageThumbSmall;
@synthesize zoomFactor = _zoomFactor;
@synthesize zoomMaximum = _zoomMaximum;

#pragma mark PDFReaderContentView functions

static inline CGFloat ZoomScaleThatFits(CGSize target, CGSize source)
{
	CGFloat w_scale = (target.width / source.width);

	CGFloat h_scale = (target.height / source.height);

	return ((w_scale < h_scale) ? w_scale : h_scale);
}

#pragma mark PDFReaderContentView instance methods

- (void)updateMinimumMaximumZoom
{
	CGRect targetRect = CGRectInset(self.bounds, self.insetMargin, self.insetMargin);

	CGFloat zoomScale = ZoomScaleThatFits(targetRect.size, theContentView.bounds.size);

	self.minimumZoomScale = zoomScale; // Set the minimum and maximum zoom scales

	self.maximumZoomScale = (zoomScale * self.zoomMaximum); // Max number of zoom levels
}

- (id)initWithFrame:(CGRect)frame fileURL:(NSURL *)fileURL page:(NSUInteger)page password:(NSString *)phrase
{
	if ((self = [super initWithFrame:frame]))
	{
		self.scrollsToTop = NO;
		self.delaysContentTouches = NO;
		self.showsVerticalScrollIndicator = NO;
		self.showsHorizontalScrollIndicator = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.backgroundColor = [UIColor clearColor];
		self.userInteractionEnabled = YES;
		self.autoresizesSubviews = NO;
		self.bouncesZoom = YES;
		self.delegate = self;

    // apply global readerConfig settings, init data members
    //
    PDFReaderConfig *readerConfig = [PDFReaderConfig sharedConfig];

    _insetMargin = 4.0;
    if(!readerConfig.pageShadowsEnabled)
    {
      _insetMargin = 2.0;
    }

    _zoomFactor = 2.0;
    _zoomMaximum = 16.0;
    _pageThumbLarge = 240;
    _pageThumbSmall = 144;

		theContentView = [[PDFReaderContentPage alloc] initWithURL:fileURL page:page password:phrase];

		if (theContentView != nil) // Must have a valid and initialized content view
		{
			theContainerView = [[UIView alloc] initWithFrame:theContentView.bounds];

			theContainerView.autoresizesSubviews = NO;
			theContainerView.userInteractionEnabled = NO;
			theContainerView.contentMode = UIViewContentModeRedraw;
			theContainerView.autoresizingMask = UIViewAutoresizingNone;
			theContainerView.backgroundColor = [UIColor whiteColor];

      if(readerConfig.pageShadowsEnabled)
      {
        theContainerView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        theContainerView.layer.shadowRadius = 4.0f; theContainerView.layer.shadowOpacity = 1.0f;
        theContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:theContainerView.bounds].CGPath;
      } // pageShadowsEnabled

			self.contentSize = theContentView.bounds.size; // Content size same as view size
			self.contentOffset = CGPointMake((0.0f - self.insetMargin), (0.0f - self.insetMargin)); // Offset
			self.contentInset = UIEdgeInsetsMake(self.insetMargin, self.insetMargin, self.insetMargin, self.insetMargin);

      if(readerConfig.previewThumbEnabled)
      {
        theThumbView = [[PDFReaderContentThumb alloc] initWithFrame:theContentView.bounds]; // Page thumb view

        [theContainerView addSubview:theThumbView]; // Add the thumb view to the container view
      } // previewThumbEnabled

			[theContainerView addSubview:theContentView]; // Add the content view to the container view

			[self addSubview:theContainerView]; // Add the container view to the scroll view

			[self updateMinimumMaximumZoom]; // Update the minimum and maximum zoom scales

			self.zoomScale = self.minimumZoomScale; // Set zoom to fit page content
		}

		[self addObserver:self forKeyPath:@"frame" options:0 context:PDFReaderContentViewContext];

		self.tag = page; // Tag the view with the page number
	}

	return self;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"frame" context:PDFReaderContentViewContext];
}

- (void)showPageThumb:(NSURL *)fileURL page:(NSInteger)page password:(NSString *)phrase guid:(NSString *)guid
{
  if([PDFReaderConfig sharedConfig].previewThumbEnabled)
  {
    BOOL large = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad); // Page thumb size

    CGSize size = (large ? CGSizeMake(self.pageThumbLarge, self.pageThumbLarge) : CGSizeMake(self.pageThumbSmall, self.pageThumbSmall));

    PDFReaderThumbRequest *request = [PDFReaderThumbRequest newForView:theThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];

    UIImage *image = [[PDFReaderThumbCache sharedInstance] thumbRequest:request priority:YES]; // Request the page thumb

    if ([image isKindOfClass:[UIImage class]]) [theThumbView showImage:image]; // Show image from cache
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == PDFReaderContentViewContext) // Our context
	{
		if ((object == self) && [keyPath isEqualToString:@"frame"])
		{
			CGFloat oldMinimumZoomScale = self.minimumZoomScale;

			[self updateMinimumMaximumZoom]; // Update zoom scale limits

			if (self.zoomScale == oldMinimumZoomScale) // Old minimum
			{
				self.zoomScale = self.minimumZoomScale;
			}
			else // Check against minimum zoom scale
			{
				if (self.zoomScale < self.minimumZoomScale)
				{
					self.zoomScale = self.minimumZoomScale;
				}
				else // Check against maximum zoom scale
				{
					if (self.zoomScale > self.maximumZoomScale)
					{
						self.zoomScale = self.maximumZoomScale;
					}
				}
			}
		}
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	CGSize boundsSize = self.bounds.size;
	CGRect viewFrame = theContainerView.frame;

	if (viewFrame.size.width < boundsSize.width)
		viewFrame.origin.x = (((boundsSize.width - viewFrame.size.width) / 2.0f) + self.contentOffset.x);
	else
		viewFrame.origin.x = 0.0f;

	if (viewFrame.size.height < boundsSize.height)
		viewFrame.origin.y = (((boundsSize.height - viewFrame.size.height) / 2.0f) + self.contentOffset.y);
	else
		viewFrame.origin.y = 0.0f;

	theContainerView.frame = viewFrame;
}

- (id)processSingleTap:(UITapGestureRecognizer *)recognizer
{
	return [theContentView processSingleTap:recognizer];
}

- (void)zoomIncrement
{
	CGFloat zoomScale = self.zoomScale;

	if (zoomScale < self.maximumZoomScale)
	{
		zoomScale *= self.zoomFactor; // Zoom in

		if (zoomScale > self.maximumZoomScale)
		{
			zoomScale = self.maximumZoomScale;
		}

		[self setZoomScale:zoomScale animated:YES];
	}
}

- (void)zoomDecrement
{
	CGFloat zoomScale = self.zoomScale;

	if (zoomScale > self.minimumZoomScale)
	{
		zoomScale /= self.zoomFactor; // Zoom out

		if (zoomScale < self.minimumZoomScale)
		{
			zoomScale = self.minimumZoomScale;
		}

		[self setZoomScale:zoomScale animated:YES];
	}
}

- (void)zoomReset
{
	if (self.zoomScale > self.minimumZoomScale)
	{
		self.zoomScale = self.minimumZoomScale;
	}
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return theContainerView;
}

#pragma mark UIResponder instance methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event]; // Message superclass

	[message contentView:self touchesBegan:touches]; // Message delegate
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesCancelled:touches withEvent:event]; // Message superclass
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event]; // Message superclass
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event]; // Message superclass
}

@end

#pragma mark -

//
//	PDFReaderContentThumb class implementation
//

@implementation PDFReaderContentThumb

#pragma mark PDFReaderContentThumb instance methods

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) // Superclass init
	{
		imageView.contentMode = UIViewContentModeScaleAspectFill;

		imageView.clipsToBounds = YES; // Needed for aspect fill
	}

	return self;
}

@end
