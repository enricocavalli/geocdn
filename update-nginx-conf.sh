#!/bin/sh

cd /etc/nginx/geocdn/
git pull
/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf -s reload
