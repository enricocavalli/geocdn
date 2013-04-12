#!/bin/sh

wget http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNumv6.dat.gz
gunzip -f GeoIPASNumv6.dat.gz

wget http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz
gunzip -f GeoIPv6.dat
