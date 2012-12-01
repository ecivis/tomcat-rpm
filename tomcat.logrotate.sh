/var/log/tomcat/catalina.out {
    copytruncate
    daily
    rotate 10
    missingok
    compress
    size 10M
}

