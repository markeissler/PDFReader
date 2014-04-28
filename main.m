//
//	main.m
//	Reader v2.6.0
//
//	Created by Julius Oklamcak on 2011-07-01.
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

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
	@autoreleasepool
	{
    //
    // Define READER_BOOK_DEMO to build ReaderBookDelegate exmaple.
    //
    // ReaderAppDelegate creates a demo that enables multimode, which could be
    // used to implement a generic reader, allowing the user to switch among
    // a list of pdfs. For the demo, the user is just presented with a target
    // ("TAP") that triggers the display of the last pdf found in the bundle. If
    // you modify the example, you could provide multiple tap targets.
    //
    // ReaderBookDelegate creates a demo that displays the last pdf found in the
    // app bundle.
    //
#define READER_BOOK_DEMO
#ifdef READER_BOOK_DEMO
    return UIApplicationMain(argc, argv, nil, @"ReaderBookDelegate");
#else
		return UIApplicationMain(argc, argv, nil, @"ReaderAppDelegate");
#endif
	}
}
