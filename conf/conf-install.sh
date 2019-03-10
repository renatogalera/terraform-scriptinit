#!/bin/bash
yum -y update
yum -y install docker epel-release curl
cp -R /tmp/docker /home/
curl ifconfig.me >> /home/docker/index.html
cd /home/docker/
systemctl enable docker
systemctl restart docker
docker build -t app-idwall .
docker container run -dit --name web-app -p 443:443 -p 80:80 app-idwall
exit 0