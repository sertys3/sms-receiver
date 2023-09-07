#!/bin/sh
#Do not run directly. This is a helper script for make.

BINDIR=$1
if [ -z "$BINDIR" ]; then
  BINDIR=/usr/local/bin
fi

echo "You are going to delete all files from the SMS Server Tools."
echo "This script deletes also the config file and stored messages."
echo "Are you sure to proceed? [yes/no]"
read answer
if [ "$answer" != "yes" ]; then
  echo "Did NOT proceed, exiting..."
  exit 1
fi

echo "Deleting binary program files"
# For Cygwin "smsd" and "smsd.exe" are the same while searching files,
# but rm needs a complete name.
[ -f $BINDIR/smsd.exe ] && rm $BINDIR/smsd.exe
[ -f $BINDIR/smsd ] && rm $BINDIR/smsd
[ -f $BINDIR/putsms ] && rm $BINDIR/putsms
[ -f $BINDIR/getsms ] && rm $BINDIR/getsms

echo "Deleting some scripts"
[ -f $BINDIR/pkill ] && echo "skipped $BINDIR/pkill, other programs might need it."
[ -f $BINDIR/sendsms ] && rm $BINDIR/sendsms
[ -f $BINDIR/sms2html ] && rm $BINDIR/sms2html
[ -f $BINDIR/sms2unicode ] && rm $BINDIR/sms2unicode
[ -f $BINDIR/unicode2sms ] && rm $BINDIR/unicode2sms

echo "Deleting config file"
[ -f /etc/smsd.conf ] && rm /etc/smsd.conf

echo "Deleting start-script"
[ -d /etc/init.d ] && rm /etc/init.d/sms3
[ -d /sbin/init.d ] && rm /sbin/init.d/sms3

echo "Deleting spool directories"
[ -d /var/spool/sms ] && rm -R /var/spool/sms
