#!/bin/bash
CWD=$(pwd)
SPEC="tomcat.spec"
TCINIT="tomcat.init.sh"

MAJOR_VERSION=$(awk '/%define major_version/ {print $3}' ${SPEC})
MINOR_VERSION=$(awk '/%define minor_version/ {print $3}' ${SPEC})
MICRO_VERSION=$(awk '/%define micro_version/ {print $3}' ${SPEC})
VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${MICRO_VERSION}"

SOURCE_URL="http://www.apache.org/dist/tomcat/tomcat-${MAJOR_VERSION}/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz"
SOURCE1=$(awk '/Source1: / {print $2}' ${SPEC})
SOURCE2=$(awk '/Source2: / {print $2}' ${SPEC})
SOURCE3=$(awk '/Source3: / {print $2}' ${SPEC})
SOURCE5=$(awk '/Source5: / {print $2}' ${SPEC}) # setenv.sh

which wget > /dev/null
if [ $? -ne 0 ]; then
  echo "Aborting. Cannot continue without wget."
  exit 1
fi

which rpmbuild > /dev/null
if [ $? -ne 0 ]; then
  echo "Aborting. Cannot continue without rpmbuild from the rpm-build package."
  exit 1
fi

# The community packages install to /usr/java/...
# but the RedHat packages install to /usr/lib/jvm/...
echo "Determinig JAVA_HOME..."
if [ -a /usr/lib/jvm/java ]; then
  JHOME="/usr/lib/jvm/java"
  JDKREQ="java-sdk"
elif [ -a /usr/java/latest ]; then
  JHOME="/usr/java/latest"
  JDKREQ="jdk"
else
  echo "Couldn't locate a standard Java install. Aborting!"
  exit 1
fi

echo "Updating init script with real JAVA_HOME..."
JHOME_ESCAPED=$(echo "${JHOME}" | sed -e 's/[\/&]/\\&/g')
sed -i 's/^\(JAVA_HOME=\)\(.*\)$/\1"'${JHOME_ESCAPED}'"/' ${TCINIT}

echo "Creating RPM build path structure..."
mkdir -p rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS,tmp}

cp ${SOURCE1} ${SOURCE2} ${SOURCE3} ${SOURCE5} rpmbuild/SOURCES/

echo "Downloading sources..."
cd rpmbuild/SOURCES
if [ -f apache-tomcat-${VERSION}.tar.gz ]; then
  # We'll remove it just to be sure we have a good
  # package to start with.
  rm apache-tomcat-${VERSION}.tar.gz
fi
wget ${SOURCE_URL}

# Thank you for the wackadoo packaging Apache.
# And you, RPM, for being a total POS.
tar zxf apache-tomcat-${VERSION}.tar.gz
cp apache-tomcat-${VERSION}/bin/tomcat-native.tar.gz .
cp apache-tomcat-${VERSION}/bin/commons-daemon-native.tar.gz .
rm -rf apache-tomcat-${VERSION}

tar zxf tomcat-native.tar.gz
rm tomcat-native.tar.gz
A=$(find . -maxdepth 1 -type d -name 'tomcat-native*')
mv ${A:2} tcnative
tar cf - tcnative | gzip -- - > tomcat-native.tar.gz
rm -rf tcnative

tar zxf commons-daemon-native.tar.gz
rm commons-daemon-native.tar.gz
B=$(find . -maxdepth 1 -type d -name 'commons-daemon*')
mv ${B:2} commons-daemon
tar cf - commons-daemon | gzip -- - > commons-daemon-native.tar.gz
rm -rf commons-daemon

echo "Building RPM..."
cd ${CWD}
rpmbuild --define "_topdir ${CWD}/rpmbuild" --define "_java_home ${JHOME}" \
  --define "_jdk_require ${JDKREQ}" -ba ${SPEC}

