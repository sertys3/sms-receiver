#!/bin/sh
#Do not run directly. This is a helper script for make.

BINDIR=$1
if [ -z "$BINDIR" ]; then
  BINDIR=/usr/local/bin
fi

makepath()
{
  p="$1"
  (
    # Absolut Unix.
    if echo $p | grep '^/' >/dev/null
    then
      cd /
    fi

    # This will break if $1 contains a space.
    for c in `echo $p | tr '/' ' '`
    do
      if [ -d "$c" ] || mkdir "$c"
      then
        cd "$c" || return $?
      else
        echo "failed to create $c" >&2; return $?
      fi
    done
  )
}

copy()
{
  if [ -f $2 ]; then
    echo "  Skipped $2, file already exists"
  else  
    echo "  $2"
    cp $1 $2
  fi        
}

forcecopy()
{
  if [ -f $2 ]; then
    echo "  Overwriting $2"
    cp $1 $2
  else
    echo "  $2"
    cp $1 $2
  fi
}

delete()
{
  if [ -f $1 ]; then
    echo " Deleting $1"
    rm $1
  fi
}

makedir()
{
  if [ -d $1 ]; then
    echo "  Skipped $1, directory already exists"
  else
    echo "  Creating directory $1"
    mkdir $1
  fi
}

echo ""
if [ ! -f src/smsd ] && [ ! -f src/smsd.exe ]; then 
  echo 'Please run "make -s install" instead.'
  exit 1
fi

echo "Installing binary program files"
makepath $BINDIR
if [ -f src/smsd.exe ]; then
  forcecopy src/smsd.exe $BINDIR/smsd.exe
else
  forcecopy src/smsd $BINDIR/smsd
fi
delete $BINDIR/getsms
delete $BINDIR/putsms

echo "Installing some scripts"
copy scripts/sendsms $BINDIR/sendsms
copy scripts/sms2html $BINDIR/sms2html
copy scripts/sms2unicode $BINDIR/sms2unicode
copy scripts/unicode2sms $BINDIR/unicode2sms

echo "Installing config file"
copy examples/smsd.conf.easy /etc/smsd.conf

echo "Creating minimum spool directories"
makedir /var/spool
makedir /var/spool/sms
makedir /var/spool/sms/incoming
makedir /var/spool/sms/outgoing
makedir /var/spool/sms/checked

echo "Installing start-script"
SMS3SCRIPT=scripts/sms3
if [ -d /etc/init.d ]; then
  copy scripts/sms3 /etc/init.d/sms3
  SMS3SCRIPT=/etc/init.d/sms3
elif [ -d /sbin/init.d ]; then
  copy scripts/sms3 /sbin/init.d/sms3
  SMS3SCRIPT=/sbin/init.d/sms3
else
  echo "  I do not know where to copy scripts/sms3. Please find out yourself."
fi

echo ""
echo "Example script files are not installed automatically."
echo 'Please dont forget to edit /etc/smsd.conf.'
if [ "$BINDIR" != "/usr/local/bin" ]; then
  echo "You have installed executables to $BINDIR,"
  echo "you should manually edit $SMS3SCRIPT script."
fi
