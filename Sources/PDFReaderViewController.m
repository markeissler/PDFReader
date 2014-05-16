//
//	PDFReaderViewController.m
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
#import "PDFReaderViewController.h"
#import "ThumbsViewController.h"
#import "PDFReaderMainToolbar.h"
#import "PDFReaderMainPagebar.h"
#import "PDFReaderContentView.h"
#import "PDFReaderThumbCache.h"
#import "PDFReaderThumbQueue.h"

#import <MessageUI/MessageUI.h>

@interface PDFReaderViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate,
									PDFReaderMainToolbarDelegate, PDFReaderMainPagebarDelegate, PDFReaderContentViewDelegate, ThumbsViewControllerDelegate>
@end

@implementation PDFReaderViewController
{
	PDFReaderDocument *document;

	UIScrollView *theScrollView;

	PDFReaderMainToolbar *mainToolbar;

	PDFReaderMainPagebar *mainPagebar;

	NSMutableDictionary *contentViews;

	UIPrintInteractionController *printInteraction;

	NSInteger currentPage;

	CGSize lastAppearSize;

	NSDate *lastHideTime;

	BOOL isVisible;
}

#pragma mark Constants

/**
 *  Size of the contentViews "window" buffer represented as previous and
 *    subsequent pages (each a contentView) added to theScrollView as subviews.
 *    Usually, 3 is enough (one page before and one after the target). Setting
 *    to 1 will result in the display of a single page. Usually, an odd number.
 */
const NSInteger kPDFReaderDefaultPagingViews = 3;

const CGFloat kPDFReaderDefaultStatusBarHeight = 20.0f;
const CGFloat kPDFReaderDefaultToolBarHeight = 44.0f;
const CGFloat kPDFReaderDefaultPageBarHeight = 48.0f;
const CGFloat kPDFReaderDefaultTapAreaSize = 48.0f;

#pragma mark Properties

@synthesize delegate;

#pragma mark Support methods

- (void)updateScrollViewContentSize
{
  NSInteger pageCount = [document.pageCount integerValue];

  // Limit theScrollView width to the size of the contentViews window
  if (pageCount > kPDFReaderDefaultPagingViews)
    pageCount = kPDFReaderDefaultPagingViews;

  CGFloat contentHeight = theScrollView.bounds.size.height;

  CGFloat contentWidth = (theScrollView.bounds.size.width * pageCount);

  theScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateScrollViewContentViews
{
  // Update theScrollView content size
  [self updateScrollViewContentSize];

  NSMutableIndexSet* pageSet = [NSMutableIndexSet indexSet];

  // Enumerate contentViews and add page number of each view to pageSet
  [contentViews
      enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL* stop) {
          PDFReaderContentView* contentView = object;
          [pageSet addIndex:contentView.tag];
      }];

  __block CGRect viewRect = CGRectZero;
  viewRect.size = theScrollView.bounds.size;

  __block CGPoint contentOffset = CGPointZero;
  NSInteger page = [document.pageNumber integerValue];

  // Enumerate pageSet and update each contentView's viewRect, we increase
  // the width of the viewRect as we go along, and save the contentOffset of
  // our current selected page when we come across it.
  [pageSet enumerateIndexesUsingBlock:^(NSUInteger number, BOOL* stop) {
      NSNumber* key = [NSNumber numberWithInteger:number];

      PDFReaderContentView* contentView = [contentViews objectForKey:key];

      contentView.frame = viewRect;
      if (page == number)
        contentOffset = viewRect.origin;

      // Next view frame position
      viewRect.origin.x += viewRect.size.width;
  }];
  
  // Update theScrollView content offset if needed
  if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset)
      == false) {
    theScrollView.contentOffset = contentOffset;
  }
}

- (void)updateToolbarBookmarkIcon
{
	NSInteger page = [document.pageNumber integerValue];

	BOOL bookmarked = [document.bookmarks containsIndex:page];

	[mainToolbar setBookmarkState:bookmarked];
}

- (void)showDocumentPage:(NSInteger)page
{
  if (page == currentPage)
    return;

  NSInteger minValue;
  NSInteger maxValue;
  NSInteger minPage = 1;
  NSInteger maxPage = [document.pageCount integerValue];

  // number of contentViews added to parent view (theScrollView)
  NSInteger pagingViews = kPDFReaderDefaultPagingViews;
  
  if ((page < minPage) || (page > maxPage)) return;
  
  // Determine beginning and end point (in pages) of our contentView buffer,
  // which acts like a "window" where most times, our target page is in the
  // middle of the stack, surrounded by previous and subsequent pages. Each
  // pages is stuffed in a contentView.
  minValue = (page - floorf(pagingViews/2));
  maxValue = (page + floorf(pagingViews/2));
  if (minValue < minPage) {
    minValue = 1;
    maxValue = MIN(minValue + (pagingViews - 1), maxPage);
  } else if (maxValue > maxPage) {
    minValue = MAX(maxPage - (pagingViews - 1), 1);
    maxValue = maxPage;
  }

  NSMutableIndexSet *newPageSet = [NSMutableIndexSet new];
  NSMutableDictionary *unusedViews = [contentViews mutableCopy];
  CGRect viewRect = CGRectZero;
  viewRect.size = theScrollView.bounds.size;

  for (NSInteger number = minValue; number <= maxValue; number++)
  {
    NSNumber *key = [NSNumber numberWithInteger:number];
    PDFReaderContentView *contentView = [contentViews objectForKey:key];

    if (contentView == nil) {
      // Page not present in contentViews array, create a new document content
      // view and add it.
      NSURL *fileURL = document.fileURL;
      NSString *phrase = document.password;

      contentView = [[PDFReaderContentView alloc] initWithFrame:viewRect
                                                        fileURL:fileURL
                                                           page:number
                                                       password:phrase];

      [theScrollView addSubview:contentView];
      [contentViews setObject:contentView forKey:key];

      contentView.message = self;
      [newPageSet addIndex:number];
    } else {
      // Reposition the existing content view
      contentView.frame = viewRect;
      [contentView zoomReset];

      // Remove unusedViews
      [unusedViews removeObjectForKey:key];
    }

    viewRect.origin.x += viewRect.size.width;
  }

  // Remove unused views and release mutable dictionary object
  [unusedViews enumerateKeysAndObjectsUsingBlock:
    ^(id key, id object, BOOL *stop)
    {
      [contentViews removeObjectForKey:key];

      PDFReaderContentView *contentView = object;

      [contentView removeFromSuperview];
    }
  ];
  unusedViews = nil;

  CGFloat contentViewWidth = viewRect.size.width;
  CGPoint contentOffset = CGPointZero;

  // Determine offset from first contentView (subview) to target, then update
  // theScrollView content offset if needed.
  NSInteger targetViewOffset = (page - minValue);
  contentOffset.x = contentViewWidth * targetViewOffset;
  if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == false)
  {
    theScrollView.contentOffset = contentOffset;
  }

  // Update document page number if different from page
  if ([document.pageNumber integerValue] != page)
  {
    document.pageNumber = [NSNumber numberWithInteger:page];
  }

  NSURL *fileURL = document.fileURL; NSString *phrase = document.password; NSString *guid = document.guid;

  // Preview visible page first
  if ([newPageSet containsIndex:page] == YES)
  {
    NSNumber *key = [NSNumber numberWithInteger:page];

    PDFReaderContentView *targetView = [contentViews objectForKey:key];

    [targetView showPageThumb:fileURL page:page password:phrase guid:guid];

    // Remove visible page from set
    [newPageSet removeIndex:page];
  }

  // Show previews
  [newPageSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:
    ^(NSUInteger number, BOOL *stop)
    {
      NSNumber *key = [NSNumber numberWithInteger:number];

      PDFReaderContentView *targetView = [contentViews objectForKey:key];

      [targetView showPageThumb:fileURL page:number password:phrase guid:guid];
    }
  ];

  // Release new page set
  newPageSet = nil;

  // Update the pagebar display
  [mainPagebar updatePagebar];

  // Update bookmark
  [self updateToolbarBookmarkIcon];

  // Track current page number
  currentPage = page;
}

- (void)showDocument:(id)object
{
  // Update theScrollView content size
	[self updateScrollViewContentSize];

	[self showDocumentPage:[document.pageNumber integerValue]];

	document.lastOpen = [NSDate date];

	isVisible = YES;
}

#pragma mark UIViewController methods

// Override UIViewController's designated initalizer to throw an exception
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  @throw [NSException exceptionWithName:@"Wrong initalizer"
                                 reason:@"Call initWithReaderDocument"
                                 userInfo:nil];
  
  return nil;
}

// Designated initialzer
- (instancetype)initWithReaderDocument:(PDFReaderDocument *)object {

  if (object == nil)
    @throw [NSException exceptionWithName:@"Missing arguments"
                                   reason:@"object is nil"
                                 userInfo:nil];
  
  if (![object isKindOfClass:[PDFReaderDocument class]])
    @throw [NSException exceptionWithName:@"Wrong type"
                                   reason:@"object is wrong type"
                                 userInfo:nil];
  
  self = [super initWithNibName:nil bundle:nil];
  if (self)
  {
    NSNotificationCenter *notificationCenter =
        [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWill:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWill:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];

    [object updateProperties];
    
    // Retain the supplied PDFReaderDocument object for our use
    document = object;
    
    // Touch the document thumb cache directory
    [PDFReaderThumbCache touchThumbCacheWithGUID:object.guid];
  }

  return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	assert(document != nil); // Must have a valid PDFReaderDocument

	self.view.backgroundColor = [UIColor grayColor]; // Neutral gray

	CGRect scrollViewRect = self.view.bounds; UIView *fakeStatusBar = nil;

	if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) // iOS 7+
	{
		if ([self prefersStatusBarHidden] == NO) // Visible status bar
		{
			CGRect statusBarRect = self.view.bounds; // Status bar frame
			statusBarRect.size.height = kPDFReaderDefaultStatusBarHeight;
			fakeStatusBar = [[UIView alloc] initWithFrame:statusBarRect]; // UIView
			fakeStatusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			fakeStatusBar.backgroundColor = [UIColor blackColor];
			fakeStatusBar.contentMode = UIViewContentModeRedraw;
			fakeStatusBar.userInteractionEnabled = NO;

			scrollViewRect.origin.y += kPDFReaderDefaultStatusBarHeight;
      scrollViewRect.size.height -= kPDFReaderDefaultStatusBarHeight;
		}
	}

	theScrollView = [[UIScrollView alloc] initWithFrame:scrollViewRect]; // UIScrollView
	theScrollView.autoresizesSubviews = NO; theScrollView.contentMode = UIViewContentModeRedraw;
	theScrollView.showsHorizontalScrollIndicator = NO; theScrollView.showsVerticalScrollIndicator = NO;
	theScrollView.scrollsToTop = NO; theScrollView.delaysContentTouches = NO; theScrollView.pagingEnabled = YES;
	theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	theScrollView.backgroundColor = [UIColor clearColor]; theScrollView.delegate = self;
	[self.view addSubview:theScrollView];

	CGRect toolbarRect = scrollViewRect; // Toolbar frame
	toolbarRect.size.height = kPDFReaderDefaultToolBarHeight; // Default toolbar height
	mainToolbar = [[PDFReaderMainToolbar alloc] initWithFrame:toolbarRect document:document]; // PDFReaderMainToolbar
	mainToolbar.delegate = self; // PDFReaderMainToolbarDelegate
	[self.view addSubview:mainToolbar];

	CGRect pagebarRect = self.view.bounds;; // Pagebar frame
	pagebarRect.origin.y = (pagebarRect.size.height - kPDFReaderDefaultPageBarHeight);
	pagebarRect.size.height = kPDFReaderDefaultPageBarHeight; // Default pagebar height
	mainPagebar = [[PDFReaderMainPagebar alloc] initWithFrame:pagebarRect document:document]; // PDFReaderMainPagebar
	mainPagebar.delegate = self; // PDFReaderMainPagebarDelegate
	[self.view addSubview:mainPagebar];

	if (fakeStatusBar != nil) [self.view addSubview:fakeStatusBar]; // Add status bar background view

	UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;
	[self.view addGestureRecognizer:singleTapOne];

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;
	[self.view addGestureRecognizer:doubleTapOne];

	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;
	[self.view addGestureRecognizer:doubleTapTwo];

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail

	contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate date];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
	{
		if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
		{
			[self updateScrollViewContentViews]; // Update content views
		}

		lastAppearSize = CGSizeZero; // Reset view size tracking
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero)) // First time
	{
		[self performSelector:@selector(showDocument:) withObject:nil afterDelay:0.02];
	}

  if([PDFReaderConfig sharedConfig].idleTimerDisabled)
  {
    [UIApplication sharedApplication].idleTimerDisabled = YES;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

	lastAppearSize = self.view.bounds.size; // Track view size

  if([PDFReaderConfig sharedConfig].idleTimerDisabled)
  {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
  }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	mainToolbar = nil; mainPagebar = nil;

	theScrollView = nil; contentViews = nil; lastHideTime = nil;

	lastAppearSize = CGSizeZero; currentPage = 0;

	[super viewDidUnload];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (isVisible == NO) return; // iOS present modal bodge

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	if (isVisible == NO) return; // iOS present modal bodge

	[self updateScrollViewContentViews]; // Update content views

	lastAppearSize = CGSizeZero; // Reset view size tracking
}

/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//if (isVisible == NO) return; // iOS present modal bodge

	//if (fromInterfaceOrientation == self.interfaceOrientation) return;
}
*/

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	__block NSInteger page = 0;

	CGFloat contentOffsetX = scrollView.contentOffset.x;

	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			PDFReaderContentView *contentView = object;

			if (contentView.frame.origin.x == contentOffsetX)
			{
				page = contentView.tag; *stop = YES;
			}
		}
	];

	if (page != 0) [self showDocumentPage:page]; // Show the page
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[self showDocumentPage:theScrollView.tag]; // Show page

	theScrollView.tag = 0; // Clear page number tag
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
	if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;

	return NO;
}

#pragma mark UIGestureRecognizer action methods

- (void)decrementPageNumber
{
	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != minPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x -= theScrollView.bounds.size.width; // -= 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page - 1); // Decrement page number
		}
	}
}

- (void)incrementPageNumber
{
	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != maxPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x += theScrollView.bounds.size.width; // += 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page + 1); // Increment page number
		}
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect areaRect = CGRectInset(viewRect, kPDFReaderDefaultTapAreaSize, 0.0f); // Area

		if (CGRectContainsPoint(areaRect, point)) // Single tap is inside the area
		{
			NSInteger page = [document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			PDFReaderContentView *targetView = [contentViews objectForKey:key];

			id target = [targetView processSingleTap:recognizer]; // Target

			if (target != nil) // Handle the returned target object
			{
				if ([target isKindOfClass:[NSURL class]]) // Open a URL
				{
					NSURL *url = (NSURL *)target; // Cast to a NSURL object

					if (url.scheme == nil) // Handle a missing URL scheme
					{
						NSString *www = url.absoluteString; // Get URL string

						if ([www hasPrefix:@"www"] == YES) // Check for 'www' prefix
						{
							NSString *http = [NSString stringWithFormat:@"http://%@", www];

							url = [NSURL URLWithString:http]; // Proper http-based URL
						}
					}

					if ([[UIApplication sharedApplication] openURL:url] == NO)
					{
						#ifdef DEBUG
							NSLog(@"%s '%@'", __FUNCTION__, url); // Bad or unknown URL
						#endif
					}
				}
				else // Not a URL, so check for other possible object type
				{
					if ([target isKindOfClass:[NSNumber class]]) // Goto page
					{
						NSInteger value = [target integerValue]; // Number

						[self showDocumentPage:value]; // Show the page
					}
				}
			}
			else // Nothing active tapped in the target content view
			{
				if ([lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
				{
					if ((mainToolbar.hidden == YES) || (mainPagebar.hidden == YES))
					{
						[mainToolbar showToolbar]; [mainPagebar showPagebar]; // Show
					}
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = kPDFReaderDefaultTapAreaSize;
		nextPageRect.origin.x = (viewRect.size.width - kPDFReaderDefaultTapAreaSize);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = kPDFReaderDefaultTapAreaSize;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect zoomArea = CGRectInset(viewRect, kPDFReaderDefaultTapAreaSize, kPDFReaderDefaultTapAreaSize);

		if (CGRectContainsPoint(zoomArea, point)) // Double tap is in the zoom area
		{
			NSInteger page = [document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			PDFReaderContentView *targetView = [contentViews objectForKey:key];

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom ++
				{
					[targetView zoomIncrement]; break;
				}

				case 2: // Two finger double tap: zoom --
				{
					[targetView zoomDecrement]; break;
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = kPDFReaderDefaultTapAreaSize;
		nextPageRect.origin.x = (viewRect.size.width - kPDFReaderDefaultTapAreaSize);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = kPDFReaderDefaultTapAreaSize;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

#pragma mark PDFReaderContentViewDelegate methods

- (void)contentView:(PDFReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
	if ((mainToolbar.hidden == NO) || (mainPagebar.hidden == NO))
	{
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info

			CGPoint point = [touch locationInView:self.view]; // Touch location

			CGRect areaRect = CGRectInset(self.view.bounds, kPDFReaderDefaultTapAreaSize, kPDFReaderDefaultTapAreaSize);

			if (CGRectContainsPoint(areaRect, point) == false) return;
		}

		[mainToolbar hideToolbar]; [mainPagebar hidePagebar]; // Hide

		lastHideTime = [NSDate date];
	}
}

#pragma mark PDFReaderMainToolbarDelegate methods

- (void)tappedInToolbar:(PDFReaderMainToolbar *)toolbar doneButton:(UIButton *)button
{
  if(![PDFReaderConfig sharedConfig].multimodeDisabled) {
    [document saveReaderDocument]; // Save any PDFReaderDocument object changes

    [[PDFReaderThumbQueue sharedInstance] cancelOperationsWithGUID:document.guid];

    [[PDFReaderThumbCache sharedInstance] removeAllObjects]; // Empty the thumb cache

    if (printInteraction != nil) [printInteraction dismissAnimated:NO]; // Dismiss

    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
      [delegate dismissReaderViewController:self]; // Dismiss the PDFReaderViewController
    }
    else // We have a "Delegate must respond to -dismissReaderViewController: error"
    {
      NSAssert(NO, @"Delegate must respond to -dismissReaderViewController:");
    }
  } // multimodeDisabled
}

- (void)tappedInToolbar:(PDFReaderMainToolbar *)toolbar thumbsButton:(UIButton *)button
{
	if (printInteraction != nil) [printInteraction dismissAnimated:NO]; // Dismiss

	ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:document];

	thumbsViewController.delegate = self; thumbsViewController.title = self.title;

	thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	thumbsViewController.modalPresentationStyle = UIModalPresentationFullScreen;

	[self presentViewController:thumbsViewController animated:NO completion:NULL];
}

- (void)tappedInToolbar:(PDFReaderMainToolbar *)toolbar printButton:(UIButton *)button
{
  if([PDFReaderConfig sharedConfig].printButtonEnabled)
  {
    Class printInteractionController = NSClassFromString(@"UIPrintInteractionController");

    if ((printInteractionController != nil) && [printInteractionController isPrintingAvailable])
    {
      NSURL *fileURL = document.fileURL; // Document file URL

      printInteraction = [printInteractionController sharedPrintController];

      if ([printInteractionController canPrintURL:fileURL] == YES) // Check first
      {
        UIPrintInfo *printInfo = [NSClassFromString(@"UIPrintInfo") printInfo];

        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = document.fileName;

        printInteraction.printInfo = printInfo;
        printInteraction.printingItem = fileURL;
        printInteraction.showsPageRange = YES;

        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
          [printInteraction presentFromRect:button.bounds inView:button animated:YES completionHandler:
            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
            {
              #ifdef DEBUG
                if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
              #endif
            }
          ];
        }
        else // Presume UIUserInterfaceIdiomPhone
        {
          [printInteraction presentAnimated:YES completionHandler:
            ^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
            {
              #ifdef DEBUG
                if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
              #endif
            }
          ];
        }
      }
    }
  } // printButtonEnabled
}

- (void)tappedInToolbar:(PDFReaderMainToolbar *)toolbar emailButton:(UIButton *)button
{
  if([PDFReaderConfig sharedConfig].mailButtonEnabled)
  {
    if ([MFMailComposeViewController canSendMail] == NO) return;

    if (printInteraction != nil) [printInteraction dismissAnimated:YES];

    unsigned long long fileSize = [document.fileSize unsignedLongLongValue];

    if (fileSize < (unsigned long long)15728640) // Check attachment size limit (15MB)
    {
      NSURL *fileURL = document.fileURL; NSString *fileName = document.fileName; // Document

      NSData *attachment = [NSData dataWithContentsOfURL:fileURL options:(NSDataReadingMapped|NSDataReadingUncached) error:nil];

      if (attachment != nil) // Ensure that we have valid document file attachment data
      {
        MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];

        [mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];

        [mailComposer setSubject:fileName]; // Use the document file name for the subject

        mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;

        mailComposer.mailComposeDelegate = self; // Set the delegate

        [self presentViewController:mailComposer animated:YES completion:NULL];
      }
    }
  } // mailButtonEnabled
}

- (void)tappedInToolbar:(PDFReaderMainToolbar *)toolbar markButton:(UIButton *)button
{
	if (printInteraction != nil) [printInteraction dismissAnimated:YES];

	NSInteger page = [document.pageNumber integerValue];

	if ([document.bookmarks containsIndex:page]) // Remove bookmark
	{
		[mainToolbar setBookmarkState:NO]; [document.bookmarks removeIndex:page];
	}
	else // Add the bookmarked page index to the bookmarks set
	{
		[mainToolbar setBookmarkState:YES]; [document.bookmarks addIndex:page];
	}
}

#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	#ifdef DEBUG
		if ((result == MFMailComposeResultFailed) && (error != NULL)) NSLog(@"%@", error);
	#endif

	[self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss
}

#pragma mark ThumbsViewControllerDelegate methods

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
	[self updateToolbarBookmarkIcon]; // Update bookmark icon

	[self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss
}

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
	[self showDocumentPage:page]; // Show the page
}

#pragma mark PDFReaderMainPagebarDelegate methods

- (void)pagebar:(PDFReaderMainPagebar *)pagebar gotoPage:(NSInteger)page
{
	[self showDocumentPage:page]; // Show the page
}

#pragma mark UIApplication notification methods

- (void)applicationWill:(NSNotification *)notification
{
	[document saveReaderDocument]; // Save any PDFReaderDocument object changes

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}

@end
