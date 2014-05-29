
## PDFReader for iOS
**NOTICE:** PDFReader is a **fork** of the super awesome [vfr-Reader project](http://vfr.org). While PDFReader is stable, it is also a work in progress. And because this is a fork, the very latest upstream fixes and improvements may not have been incorporated into this codebase. It is also possible that some changes may never be merged back into this codebase. 

### Fork Changes
Differences between PDFReader and its upstream original source include the exposure of certain class methods at the public level along with the introduction of a singleton global config object (PDFReaderConfig) that replaces a number of defined constants. The goal is to make integration of this framework into your project much easier and that means providing ways to leverage and configure the code without having to modify the installed files.

Installation (and future updates) of PDFReader is also much easier thanks to support for the excellent [Cocoapods](http://cocoapods.org) dependency manager.

### Introduction
The [vfr-Reader project](http://vfr.org) has crafted this open source PDF reader code for fellow iOS developers struggling with wrangling PDF files onto iOS device screens.

The code is universal and does not require any XIBs (as all UI elements are code generated, allowing for greatest flexibility). It runs on iPad, iPhone and iPod touch with iOS 6.0 and up. Also supported are the Retina displays in all new devices and is ready to be fully internationalized. The idea was to provide a complete project template that you could start building from, or, just pull the required files into an existing project to enable PDF reading/viewing in your app(s).

iPod/iPhone Document View          | iPod/iPhone Pages View
-------------------------          | ----------------------
![iPod Page](http://mix-pub-dist.s3-website-us-west-1.amazonaws.com/PDFReader/img/iphone_1e.png)       | ![iPod Page](http://mix-pub-dist.s3-website-us-west-1.amazonaws.com/PDFReader/img/iphone_2e.png)

iPad Document View                 | iPad Pages View
-------------------------          | ----------------------
![iPad Page](http://mix-pub-dist.s3-website-us-west-1.amazonaws.com/PDFReader/img/ipad_1e.png) | ![iPad Thumbs](http://mix-pub-dist.s3-website-us-west-1.amazonaws.com/PDFReader/img/ipad_2e.png)

After launching the sample app, tap on the left hand side of the screen to go back a page. Tap on the right hand side to go to the next page. You can also swipe left and right to change pages. Tap on the screen to fade in the toolbar and page slider. Double-tap with one finger (or pinch out) to zoom in. Double tap with two fingers (or pinch in) to zoom out.

This implementation has been tested with large PDF files (over 250MB in size and over 2800 pages in length) and with PDF files of all flavors (from text only documents to graphics heavy magazines). It also works rather well on older devices (such as the iPod touch 4th generation and iPhone 3GS) and takes advantage of the dual-core processor (via CATiledLayer and multi-threading) in new devices.

To see an example open source PDF Viewer App that uses this code as its base, have a look at this project repository on GitHub: [https://github.com/vfr/Viewer](https://github.com/vfr/Viewer)

### Features
Multithreaded: The UI is always quite smooth and responsive.

Supports:

 - iBooks-like document navigation.
 - Device rotation and all orientations.
 - Encrypted (password protected) PDFs.
 - PDF links (URI and go to page).
 - PDFs with rotated pages.

### Building Included Demos
There are two demos included with this framework:

1. PDFReaderBookDelegate
2. PDFReaderAppDelegate

The *PDFReaderBookDelegate* builds a demo that displays the last pdf found in the app bundle. It is a *standalone* pdf reader.

The *PDFReaderAppDelegate* builds a demo that enables multimode, which could be used to implement a generic reader, allowing the user to switch among a list of pdfs. For the demo, the user is just presented with a target ("TAP") that triggers the display of the last pdf found in the bundle. If you modify the example, you could provide multiple tap targets.

By default, the *PDFReaderBookDelegate* demo will be built. To build the other demo, simply edit the *main.m* source file and comment out (or undefine) the following line:

	#define PDF_READER_BOOK_DEMO
	
Clean and re-build the project.

### Usage
The overall PDF reader functionality is encapsulated in the PDFReaderViewController class. To present a document with this class, you first need to create a PDFReaderDocument object with the file path to the PDF document and then initialize a new PDFReaderViewController with this PDFReaderDocument object. The PDFReaderViewController class uses a PDFReaderDocument object to store information about the document and to keep track of document properties (thumb cache directory path, bookmarks and the current page number for example).

An initialized PDFReaderViewController can then be presented modally, pushed onto a UINavigationController stack, placed in a UITabBarController tab, or be used as a root view controller. Please note that since PDFReaderViewController implements its own toolbar, you need to hide the UINavigationController navigation bar before pushing it and then show the navigation bar after popping it. The PDFReaderDemoController class shows how this is done with a bundled PDF file. To create a 'book as an app', please see the PDFReaderBookDelegate class.

### Installation - Cocoapods
The easiest way to install PDFReader is with [Cocoapods](http://cocoapods.org)! Add the following dependency to your project's podfile...

For a release build:

	pod "PDFReader", :git => "https://github.com/markeissler/PDFReader.git"
	
For a development build:

	pod "PDFReader", :git => "https://github.com/markeissler/PDFReader.git", 
		:branch => 'develop'

### Required iOS Frameworks
To incorporate the PDF reader code into one of your projects, all of the following iOS frameworks are required:

	UIKit, Foundation, CoreGraphics, QuartzCore, ImageIO, MessageUI

### PDFReaderConfig
To configure PDFReader at run-time you will first grab a reference to the PDFReaderConfig singleton object. The design pattern looks like this in your *App Delagate*:

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	  mainWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];	
	  // configure singleton config object before continuing!
	  PDFReaderConfig *readerConfig = [PDFReaderConfig sharedConfig];
	  readerConfig.multimodeDisabled = NO;
	  readerConfig.printButtonEnabled = YES;
	  readerConfig.mailButtonEnabled = YES;
	  ...
	}
	  
Later on, you can change or check the configuration in a similar fashion:

	if([PDFReaderConfig sharedConfig].bookmarksEnabled)
	{
	  //
	  // do something
	  //
	} // bookmarksEnabled

### PDFReaderConfig - Run Time Options
Several option properties are available through the PDFReaderConfig singleton object including those listed below. In general, properties named *"Enabled"* are **TRUE** by default; properties named *"Disabled"* are **FALSE** by default.

`BOOL` `bookmarksEnabled` - If TRUE, enables page bookmark support.

`BOOL` `mailButtonEnabled` - If TRUE, an email button is added to the toolbar
(if the device is properly configured for email support).

`BOOL` `printButtonEnabled` - If TRUE, a print button is added to the toolbar
(if printing is supported and available on the device).

`BOOL` `thumbsButtonEnabled` - If TRUE, a thumbs button is added to the toolbar
(enabling page thumbnail document navigation).

`BOOL` `pageShadowsEnabled` - If TRUE, a shadow is shown around each page
and the page content is inset by a couple of extra points.

`BOOL` `previewThumbsEnabled` - If TRUE, a medium resolution page thumbnail
is displayed before the CATiledLayer starts to render the PDF page.

`BOOL` `multimodeDisabled` - If TRUE, a "Done" button is added to the toolbar
and the -dismissReaderViewController: delegate method is messaged when
it is tapped. (Previously configured through the *standalone* #define option)

`BOOL` `idleTimerDisabled` - If TRUE, the iOS idle timer is disabled while
viewing a document (beware of battery drain).

`BOOL` `retinaSupportDisabled` - If TRUE, sets the CATiledLayer contentScale to 1.0f. This effectively disables retina support and results in non-retina device rendering speeds on retina display devices at the loss of retina display quality.

### PDFReaderDocument Archiving
To change where the property list for PDFReaderDocument objects is stored (~/Library/Application Support/ by default), see the +archiveFilePathForFileName: method. Archiving and unarchiving of the PDFReaderDocument object for a document is mandatory since this is where the current page number, bookmarks and directory of the document page thumb cache is kept.

## Bugs and such
Submit bugs by opening an issue on this project's github page.

## Appreciation
If you find PDFReader useful and would like to fund further development, you can send some kudos my way courtesy of Flattr:

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=markeissler&url=https://github.com/markeissler/PDFReader&title=PDFReader&language=bash&tags=github&category=software)

## Acknowledgements
The original codebase for PDFReader is the [vfr-Reader project](http://vfr.org) by joklamcak(at)gmail(dot)com. You can use PayPal to donate to the upstream developer(s):

[![link](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=joklamcak@gmail.com&lc=US&item_name=vfr-Reader&no_note=1&currency_code=USD)
 
The PDF link support code in the PDFReaderContentPage class is based on the links navigation code by Sorin Nistor from [http://ipdfdev.com/](http://ipdfdev.com/).

## License
This code has been made available under the MIT License.
