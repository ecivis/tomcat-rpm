#!/bin/sh
#
# tomcat	Apache Tomcat Java Servlets and JSP server
#
# chkconfig: 345 85 15
# description: Apache Tomcat Java Servlets and JSP server

source /etc/rc.d/init.d/functions

APPNAME=tomcat
USER=tomcat
LOCKFILE="/var/lock/subsys/$APPNAME"

TOMCAT_HOME="/usr/share/$APPNAME"
CATALINA_HOME="$TOMCAT_HOME"
CATALINA_BASE="/var/lib/$APPNAME"
CATALINA_OUT="/var/log/$APPNAME/catalina.out"
CATALINA_PID="/var/run/${APPNAME}/tomcat.pid"
CATALINA_OPTS="-Xmx512m -Djava.awt.headless=true"
JAVA_HOME="/usr/java/latest"


JSVC_PID="/var/run/${APPNAME}/jsvc.pid"
JSVC_CP=${TOMCAT_HOME}/bin/commons-daemon.jar:${TOMCAT_HOME}/bin/bootstrap.jar:${TOMCAT_HOME}/bin/tomcat-juli.jar
JSVC_OUT="${CATALINA_OUT}"
JSVC_ERR="/var/log/${APPNAME}/catalina.err"
if [ -r "${TOMCAT_HOME}/conf/logging.properties" ]; then
  JSVC_LOGGING="-Djava.util.logging.config.file=${TOMCAT_HOME}/conf/logging.properties"
else
  JSVC_LOGGING="-Dnop"
fi

if [ -r /etc/sysconfig/$APPNAME ]; then
  source /etc/sysconfig/$APPNAME
fi

export CATALINA_HOME CATALINA_BASE CATALINA_OUT CATALINA_PID CATALINA_OPTS JAVA_HOME

if [ "${JAVA_OPTS}" != "" ]; then
  export JAVA_OPTS
fi

function start_server {
  echo -n "Starting ${APPNAME}: "
  status -p ${JSVC_PID} ${APPNAME} > /dev/null && failure && exit
  
  source ${TOMCAT_HOME}/bin/setenv.sh
  ${TOMCAT_HOME}/bin/jsvc \
    -pidfile ${JSVC_PID} \
    -procname ${APPNAME} \
    -user ${USER} \
    -home ${JAVA_HOME} \
    -classpath ${JSVC_CP} \
    -outfile ${JSVC_OUT} \
    -errfile ${JSVC_ERR} \
    -Dcatalina.home=${CATALINA_HOME} \
    -Dcatalina.base=${CATALINA_BASE} \
    -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
    ${JSVC_LOGGING} ${JAVA_OPTS} ${CATALINA_OPTS} \
    org.apache.catalina.startup.Bootstrap

  if [ $? -eq 0 ]; then
    touch ${LOCKFILE} &&  success
  fi

  echo
}

function stop_server {
  echo -n "Stopping ${APPNAME}: "

  status -p ${JSVC_PID} ${APPNAME} > /dev/null
  if [ ! $? -eq 0 ]; then
    failure
    echo
    exit
  fi

  ${TOMCAT_HOME}/bin/jsvc -pidfile ${JSVC_PID} -stop org.apache.catalinia.startup.Bootstrap
  if [ $? -eq 0 ]; then
    rm ${LOCKFILE} && success
  else
    failure
  fi

  echo
}

case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  restart)
    stop_server
    start_server
    ;;
  condrestart)
    [ -e ${LOCKFILE} ] && $0 restart
    ;;
  status)
    status -p ${JSVC_PID} ${APPNAME}
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|condrestart|status}"
    exit 1
    ;;
esac
