#!/bin/sh
#
# STEmacsModelines:
# -*- Shell-Unix-Generic -*-
#

# Build the doxygen documentation for the project and load the docset into Xcode.
#
#  You have to set two environmental variables, or "User-Defined Settings" in Xcode for
#  This script to work properly. To achieve this:
#    1. Expand the "Targets" item in the Xcode navigation pane,
#    2. Right click on the sub-target you created the Run-Script in and select "Get-Info".
#    3. In the Info window select the "Build" tab and create two new User-Defined Settings.
#       I.   DOXYGEN_DOCSET_BUNDLE_ID - For example like a java style package name,
#            for example: 'com.yourorganization.yourproduct' this will become the name of
#            the docset bundle.
#       II.  DOXYGEN_PATH - Point the script to the location of the doxygen command-line
#            binary, Binary install locations:
#               If you downloaded the Doxygen GUI app:
#                       /Applications/Doxygen.app/Contents/Resources/doxygen
#               If you build Doxygen from Source:
#                       /usr/local/bin/doxygen

# set

PATH=/usr/local/bin:/usr/texbin:${PATH}

DOXYGEN_PATH=doxygen
if [ -z ${DOXYGEN_DOCSET_BUNDLE_ID} ]; then
  DOXYGEN_DOCSET_BUNDLE_ID=com.mixtur."${PROJECT_NAME}"
fi

if [ -z ${DOXYGEN_DOCSET_PUBLISHER_NAME} ]; then
  DOXYGEN_DOCSET_PUBLISHER_NAME="Mixtur Inc."
fi

if [ -z ${DOXYGEN_DOCSET_PUBLISHER_ID} ]; then
  DOXYGEN_DOCSET_PUBLISHER_ID=com.mixtur.${PROJECT_NAME}.${PRODUCT_NAME}
fi

if [ -z ${DOXYGEN_DOCSET_PAGE_MAIN} ]; then
  DOXYGEN_DOCSET_PAGE_MAIN="README.md"
fi

#  If the config file doesn't exist, run 'doxygen -g $SOURCE_ROOT/.doxywrite.cfg' to
#   a get default file.
if ! [ -f "$SOURCE_ROOT/.doxywrite.cfg" ]
then
  echo doxygen config file does not exist
  "$DOXYGEN_PATH" -g "$SOURCE_ROOT/.doxywrite.cfg"
fi

#  The original script appended the proper input/output directories and docset
#  info to the config file. This worked even though values are assigned higher up in the file.
#  Easier than sed? Well, sed isn't *THAT* hard. We tell sed to process the file in $TEMP_DIR
#  inline. The regular expression "s#^INPUT\ *=.*#INPUT = $SOURCE_ROOT#g" replaces
#  anything that starts with INPUT followed by zero or more spaces, followed by an '='
#  character followed by zero or more of any character with "INPUT = " and the contents
#  of $SOURCE_ROOT. At least that's what sed did when I tested this on OS X 10.6.3.

cp "$SOURCE_ROOT/.doxywrite.cfg" "$TEMP_DIR/.doxywrite.cfg"

# These three values are different for each project.
sed -e "s#^PROJECT_NAME\ *=.*#PROJECT_NAME = \"${PROJECT_NAME}\"#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^INPUT\ *=.*#INPUT = \"$SOURCE_ROOT\"#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^OUTPUT_DIRECTORY\ *=.*#OUTPUT_DIRECTORY = \"$TEMP_DIR/DoxygenDocs.docset\"#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^DOCSET_BUNDLE_ID\ *=.*#DOCSET_BUNDLE_ID = $DOXYGEN_DOCSET_BUNDLE_ID#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^DOCSET_PUBLISHER\ *=.*#DOCSET_PUBLISHER = $DOXYGEN_DOCSET_PUBLISHER_NAME#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^DOCSET_PUBLISHER_ID\ *=.*#DOCSET_PUBLISHER_ID = $DOXYGEN_DOCSET_PUBLISHER_ID#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Use the README.md file as the main page (index.html)
sed -e "s#^USE_MDFILE_AS_MAINPAGE\ *=.*#USE_MDFILE_AS_MAINPAGE = ${DOXYGEN_DOCSET_PAGE_MAIN}#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Tell doxygen to generate a docset.
sed -e "s#^GENERATE_DOCSET\ *=.*#GENERATE_DOCSET = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

sed -e "s#^RECURSIVE\ *=.*#RECURSIVE = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^GENERATE_LATEX\ *=.*#GENERATE_LATEX = NO#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Don't repeat the @brief description in the extended class and method descriptions.
sed -e "s#^REPEAT_BRIEF\ *=.*#REPEAT_BRIEF = NO#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Javadoc style list of links at the top of the page. Beign used to Javadoc I like this.
#sed -e "s#^JAVADOC_AUTOBRIEF\ *=.*#JAVADOC_AUTOBRIEF = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Insert the @brief description into the class member list at the top of each class reference page.
sed -e "s#^INLINE_INHERITED_MEMB\ *=.*#INLINE_INHERITED_MEMB = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Extracts documentation for **everything**, including stuff you might not want the user to know about.
# You can still cause doxygen to skip stuff using special commands. If that's what you prefer uncomment
# this and comment out the two lines below this one.
sed -e "s#^EXTRACT_ALL\ *=.*#EXTRACT_ALL = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Hide undocumented members and classes. You will have to
sed -e "s#^HIDE_UNDOC_MEMBERS\ *=.*#HIDE_UNDOC_MEMBERS = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"
sed -e "s#^HIDE_UNDOC_CLASSES\ *=.*#HIDE_UNDOC_CLASSES = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Enable class diagrams if you have dot installed...
#
# >brew install graphviz
#
sed -e "s#^HAVE_DOT\ *=.*#HAVE_DOT = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Additional diagram generation tweaks..
#
#sed -e "s#^TEMPLATE_RELATIONS\ *=.*#TEMPLATE_RELATIONS = YES#g" -i "" "$TEMP_DIR/.doxywrite.cfg"

# Copy the updated config file to source directory
# cp "$TEMP_DIR/.doxywrite.cfg" "$SOURCE_ROOT/.doxywrite.cfg.out"

# Preserve a copy locally
cp -R "$TEMP_DIR/DoxygenDocs.docset" "$SOURCE_ROOT/Documentation"

#  Run doxygen on the updated config file.
#  Note: doxygen creates a Makefile that does most of the heavy lifting.
"$DOXYGEN_PATH" "$TEMP_DIR/.doxywrite.cfg"

# echo "TEMP_DIR: $TEMP_DIR"
# echo "DOXYGEN_PATH : $DOXYGEN_PATH"

#  make will invoke docsetutil. Take a look at the Makefile to see how this is done.
make -C "$TEMP_DIR/DoxygenDocs.docset/html" install

#  Construct a temporary applescript file to tell Xcode to load a docset.
rm -f "$TEMP_DIR/loadDocSet.scpt"
echo "tell application \"Xcode\"" >> $TEMP_DIR/loadDocSet.scpt
echo "load documentation set with path \"/Users/$USER/Library/Developer/Shared/Documentation/DocSets/$DOXYGEN_DOCSET_BUNDLE_ID.docset\"" >> $TEMP_DIR/loadDocSet.scpt
echo "end tell" >> "$TEMP_DIR/loadDocSet.scpt"

#  Run the load-docset applescript command.
echo "Docset: /Users/$USER/Library/Developer/Shared/Documentation/DocSets/$DOXYGEN_DOCSET_BUNDLE_ID.docset"

exit 0

osascript "$TEMP_DIR/loadDocSet.scpt"

exit 0
