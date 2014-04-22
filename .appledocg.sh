#!/bin/bash
#
# STEmacsModelines:
# -*- Shell-Unix-Generic -*-
#
PATH=/usr/local/bin:${PATH}
#if [ ${CONFIGURATION} == "Release" ]; then
APPLEDOC_PATH=appledoc
if [ $APPLEDOC_PATH ]; then
$APPLEDOC_PATH \
--project-name "${PROJECT_NAME}" \
--project-company "Mixtur Inc." \
--company-id "com.mixtur" \
--output Documentation \
--create-docset \
--install-docset \
--logformat xcode \
--keep-undocumented-objects \
--keep-undocumented-members \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--merge-categories \
--exit-threshold 2 \
--docset-platform-family iphoneos \
--ignore "*.m" \
--include "${PROJECT_DIR}/Documentation/Images" \
--ignore "LoadableCategory.h" \
--index-desc "${PROJECT_DIR}/README.md" \
"${PROJECT_DIR}"
fi;
#fi;
