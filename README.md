tomcat-rpm
==========

This project defines a build system for building Apache Tomcat 7.0.x
source and binary RPM files. The included `build.sh` *must* be used to kick off
the RPM building process. The SPEC file assumes various work is done by the
script; e.g. the Tomcat packages being extracted and compiled in the corre
locations. 

Further, the SPEC file relies on `_java_home` and `_jdk_require` build variables
to be set according to the Java packages installed on the build system (and, in
turn, the target install system[s]). That is, if you are using the community
build Java packages, these variables will be set to "/usr/java/latest" and
"jdk", respectively. If you are using the RedHat packages, like the
java-1.7.0-oracle and java-1.7.0-oracle-devel packages, then they would be
set to "/usr/lib/jvm/java" and "java-sdk". The `build.sh` script does this
for you.

