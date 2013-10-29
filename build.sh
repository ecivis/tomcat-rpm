#!/bin/bash
CWD=$(pwd)
SPEC="tomcat.spec"

MAJOR_VERSION=$(awk '/%define major_version/ {print $3}' ${SPEC})
MINOR_VERSION=$(awk '/%define minor_version/ {print $3}' ${SPEC})
MICRO_VERSION=$(awk '/%define micro_version/ {print $3}' ${SPEC})
VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${MICRO_VERSION}"

SOURCE_URL="http://www.apache.org/dist/tomcat/tomcat-${MAJOR_VERSION}/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz"
SOURCE1=$(awk '/Source1: / {print $2}' ${SPEC})
SOURCE2=$(awk '/Source2: / {print $2}' ${SPEC})
SOURCE3=$(awk '/Source3: / {print $2}' ${SPEC})

mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,tmp}

cp ${SOURCE1} ${SOURCE2} ${SOURCE3} rpmbuild/SOURCES/

echo "Downloading sources ..."
cd rpmbuild/SOURCES
wget ${SOURCE_URL}

echo "Building RPM ..."
cd ${CWD}
rpmbuild --define "_topdir ${CWD}/rpmbuild" -ba tomcat.spec
