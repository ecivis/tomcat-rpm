#!/bin/sh
#
# tomcat	Apache Tomcat Java Servlets and JSP server
#
# chkconfig: 345 85 15
# description: Apache Tomcat Java Servlets and JSP server

. /etc/rc.d/init.d/functions

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


if [ -r /etc/sysconfig/$APPNAME ]; then
  . /etc/sysconfig/$APPNAME
fi

export CATALINA_HOME CATALINA_BASE CATALINA_OUT CATALINA_PID CATALINA_OPTS JAVA_HOME

case "$1" in
  start)
        echo -n "Starting ${APPNAME}: "
        status -p $CATALINA_PID $APPNAME > /dev/null && failure || (su -p -s /bin/sh $USER -c "$TOMCAT_HOME/bin/catalina.sh start" > /dev/null && (touch $LOCKFILE ; success))
        echo
        ;;
  stop)
        echo -n "Stopping ${APPNAME}: "
        status -p $CATALINA_PID $APPNAME > /dev/null && su -p -s /bin/sh $USER -c "$TOMCAT_HOME/bin/catalina.sh stop" > /dev/null && (rm -f $LOCKFILE ; success) || failure
        echo
        ;;
  restart)
        $0 stop
        $0 start
        ;;
  condrestart)
       [ -e $LOCKFILE ] && $0 restart
       ;;
  status)
        status -p $CATALINA_PID $APPNAME
        ;;
  *)
        echo "Usage: $0 {start|stop|restart|condrestart|status}"
        exit 1
        ;;
esac
