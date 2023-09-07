#!/bin/sh
# This script is used by the author to make a tar.gz package

VERSION=`cat src/version.h | tr -d '"' | awk '/smsd_version/ {print $3}'`
PACKAGE=smstools3-$VERSION.tar.gz

cd ..
tar -chzf $PACKAGE --exclude='*~' --exclude='*.bak' --exclude='*.pdf' --exclude='*.tar.gz' smstools3
echo "Package $PACKAGE created"
