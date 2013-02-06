#!/usr/bin/env bash
CONFIG_FILENAME="config.cfg"
SPEC_FILENAME="tomcat.spec"
MAJOR_VERSION=7
NEW_VERSION_FOUND=0


function cleanup_rpmmacros {

	if [  -f ~/.rpmmacros.bak  ]; then
		echo "clean up rpmmacros"
		mv -f ~/.rpmmacros.bak ~/.rpmmacros
	fi
}


function checkError {
	if [ $ERR -eq 1 ]; then
		echo "failed to build rpm" >&2
		cleanup_rpmmacros
		exit 2
	fi
}


if [ -e $CONFIG_FILENAME ]; then
	echo "Reading config...." >&2
	# check if the file contains something we don't want
	if egrep -q -v '^#|^[^ ]*=[^;]*' "$CONFIG_FILENAME"; then
	  echo "Config file is unclean, cleaning it..." >&2
	  exit 1
	fi
	source $CONFIG_FILENAME
fi

tagbase=`svn log -v http://svn.apache.org/repos/asf/tomcat/tc7.0.x/tags/ | awk '/^   A/ { print $2 }' | head -1 `

if [ -z "$MINOR_VERSION" ]; then
	MINOR_VERSION=0
fi;
OLD_MINOR_VERSION=$MINOR_VERSION

tmp=`echo $tagbase | awk '{ print substr($0,length("/tomcat/tc7.0.x/tags/TOMCAT_7_")+1, length($0)); }' | awk '{ sub(/_[0-9]*/,"",$0); print $0 }'  `
if [ $MINOR_VERSION -lt $tmp ]; then
	MINOR_VERSION=$tmp
	NEW_VERSION_FOUND=1
fi

if [ -z "$MICRO_VERSION" ]; then
	MICRO_VERSION=33
fi;
OLD_MICRO_VERSION=$MICRO_VERSION

tmp=`echo $tagbase | awk '{ print substr($0,length("/tomcat/tc7.0.x/tags/TOMCAT_7_0_")+1, length($0)); }' `
if [ $MICRO_VERSION -lt $tmp ]; then
	MICRO_VERSION=$tmp
	NEW_VERSION_FOUND=1
fi

if [ $NEW_VERSION_FOUND -eq 1 ]; then

echo "new version found!" >&2
VERSION=$MAJOR_VERSION.$MINOR_VERSION.$MICRO_VERSION
echo "$VERSION" >&2

buildroot=`pwd`/target
if [ ! -d "$buildroot" ]; then
	echo "create build directories" >&2
	mkdir $buildroot
	mkdir $buildroot/BUILD
	mkdir $buildroot/RPMS
	mkdir $buildroot/SOURCES
	mkdir $buildroot/SPECS
	mkdir $buildroot/SRPMS
	mkdir $buildroot/tmp
fi

if [  -f ~/.rpmmacros  ]; then
	echo "backup rpmmacros! " >&2
	mv -f ~/.rpmmacros ~/.rpmmacros.bak
fi
echo %_topdir $buildroot/ > ~/.rpmmacros
echo %_tmppath $buildroot/tmp >> ~/.rpmmacros

#echo '%_signature gpg' >> ~/.rpmmacros
#echo '%_gpg_name Django' >> ~/.rpmmacros



echo "download source file" >&2

wget -q -o /dev/null  http://www.apache.org/dist/tomcat/tomcat-$MAJOR_VERSION/v$VERSION/bin/apache-tomcat-$VERSION.tar.gz
if [  ! -f "./apache-tomcat-$VERSION.tar.gz"  ]; then
	echo "download failed" >&2
	cleanup_rpmmacros
	exit 3
fi

echo "copy buildfiles into source folder" >&2
mv "apache-tomcat-$VERSION.tar.gz" "$buildroot/SOURCES/apache-tomcat-$VERSION.tar.gz"
cp -f tomcat.init.sh "$buildroot/SOURCES/"
cp -f tomcat.logrotate.sh  "$buildroot/SOURCES/"
cp -f tomcat.sysconfig  "$buildroot/SOURCES/"

echo "update spec file" >&2
cat "$SPEC_FILENAME"  | sed "s/%define minor_version $OLD_MINOR_VERSION/%define minor_version $MINOR_VERSION/g" | sed "s/%define micro_version $OLD_MICRO_VERSION/%define micro_version $MICRO_VERSION/g" > $SPEC_FILENAME.tmp
mv -f  $SPEC_FILENAME.tmp $SPEC_FILENAME
cp -f $SPEC_FILENAME $buildroot/SOURCES/

rpmbuild -ba $SPEC_FILENAME
#rpmbuild -ba --sign $SPEC_FILENAME

ERR=$?
checkError

cleanup_rpmmacros

echo "MAJOR_VERSION=$MAJOR_VERSION" > $CONFIG_FILENAME
echo "MINOR_VERSION=$MINOR_VERSION" >> $CONFIG_FILENAME
echo "MICRO_VERSION=$MICRO_VERSION" >> $CONFIG_FILENAME

else
	echo "doesn't found a new tomcat" >&2
fi





exit 0