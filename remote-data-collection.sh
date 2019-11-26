#!/bin/sh
#CPU usage
date +'%Y-%m-%d %H:%M:%S' | tr '\n' ' ' | ssh -i /root/.ssh/id_rsa alex@<target> -T "cat >>
/home/alex/logs/loadavg"
cat /proc/loadavg | ssh -i /root/.ssh/id_rsa alex@<target> -T "cat >> /home/alex/logs/loadavg"
#Memory usage
date +'%Y-%m-%d %H:%M:%S' | tr '\n' ' ' | ssh -i /root/.ssh/id_rsa alex@<target> -T "cat >>
/home/alex/logs/meminfo"
free -h | grep Mem | cut -d ' ' -f 2- | ssh -i /root/.ssh/id_rsa alex@<target> -T "cat >> /home
/alex/logs/meminfo"
#Disk usage
date +'%Y-%m-%d %H:%M:%S' | tr '\n' ' ' | ssh -i /root/.ssh/id_rsa alex@<target> -T "cat >>
/home/alex/logs/diskfree"
df -H | grep sda3 | awk '{print $5}' | cut -d '%' -f 1 | tr '\n' ' ' | ssh -i /root/.ssh/id_rsa
alex@<target> -T "cat >> /home/alex/logs/diskfree"
