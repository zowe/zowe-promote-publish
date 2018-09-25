#!/bin/bash -e

################################################################################
# This program and the accompanying materials are made available under the terms of the
# Eclipse Public License v2.0 which accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright IBM Corporation 2018
################################################################################

################################################################################
# This script will publish Zowe to target folder
# 
# Parameters:
# - targert directory
# - build version
# 
# zowe-{version}.pax should be placed in ~ directory
#
# Example:
# ./zowe-publish.sh /var/www/projectgiza.org/builds 0.9.0
################################################################################

ZOWE_BUILD_DIRECTORY=$1
ZOWE_BUILD_VERSION=$2
ZOWE_BUILD_FILE=zowe-$ZOWE_BUILD_VERSION.pax

# test parameters
if [ -z "$ZOWE_BUILD_DIRECTORY" ]; then
  echo "Error: build directory is missing"
  exit 1
fi
if [ -z "$ZOWE_BUILD_VERSION" ]; then
  echo "Error: build version is missing"
  exit 1
fi
if [ ! -f $ZOWE_BUILD_FILE ]; then
  echo "Error: cannot find $ZOWE_BUILD_FILE"
  exit 1
fi

# move Zowe build to target folder
echo "> move $ZOWE_BUILD_FILE to $ZOWE_BUILD_DIRECTORY/$ZOWE_BUILD_VERSION ..."
mkdir -p $ZOWE_BUILD_DIRECTORY/$ZOWE_BUILD_VERSION
mv ~/$ZOWE_BUILD_FILE $ZOWE_BUILD_DIRECTORY/$ZOWE_BUILD_VERSION
cd $ZOWE_BUILD_DIRECTORY/$ZOWE_BUILD_VERSION

# split into trunks
echo "> split Zowe build ..."
rm zowe-$ZOWE_BUILD_VERSION-part-* 2> /dev/null || true
split -b 70m -a 1 --additional-suffix=.bin $ZOWE_BUILD_FILE zowe-$ZOWE_BUILD_VERSION-part-
ls -1 zowe-$ZOWE_BUILD_VERSION-part-*.bin > zowe-$ZOWE_BUILD_VERSION-parts.txt

# generate SHA512 hash for trunks
ZOWE_SPLITED=$(ls -1 zowe-$ZOWE_BUILD_VERSION-part-*.bin)
echo "> generating hash for trunks ..."
for f in $ZOWE_SPLITED; do
  echo "  > $f"
  gpg --print-md SHA512 $f > $f.sha512
done
# generate SHA512 hash for big file
echo "> generating hash for Zowe build ..."
gpg --print-md SHA512 $ZOWE_BUILD_FILE > $ZOWE_BUILD_FILE.sha512

# show build result
echo "> build folder result:"
ls -la .

# exit successful
echo "> done"
exit 0
