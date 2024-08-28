#!/bin/bash

/usr/bin/logger 'starting script'
while true; do
  /usr/bin/logger 'running grep'
  grep -i "cannot allocate memory" /var/log/rabbitmq/startup_err > /dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    /usr/sbin/sosreport -n yum --batch --diagnose --analyze -vvvvvv > /tmp/sosreport_output 2>&1
    /usr/bin/logger RABBITMQ ISSUE FOUND!
    exit 1
  fi
  /usr/bin/logger 'running sleep'
  sleep 3
done

