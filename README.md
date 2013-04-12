# GEOCDN

This project is used too keep track of the nginx configuration used on GARR
MIRRORS, see <http://mirror.garr.it>.

Objective of this configuration is being able to redirect requests for selected URI to a proxy cache. We also want to be able to redirect based on ASnum.

To use it include geocdn.conf in the http
stanza of nginx configuration

<pre>
http {
...
include  /etc/nginx/geocdn/geocdn.conf;
...
}
</pre>

## GeoIP localization

The nginx geoip module is used to determine country and also ASnum.
We account for reverse proxies (varnish cache):

<pre>
geoip_org  /etc/nginx/geocdn/GeoIPASNumv6.dat;
geoip_country /etc/nginx/geocdn/GeoIPv6.dat;
geoip_proxy 193.206.139.32/28;
geoip_proxy 193.206.140.32/28;
</pre>

Now we only want the number of the AS not the entire description so just use a
map with regexp substituion:

<pre>
map $geoip_org $my_geoip_org  {
  ~^(?P&lt;ascode&gt;AS[0-9]+)\ .*$  $ascode;
}
</pre>

`$my_geoip_org` now contains for instance <code>AS137</code> for GARR
autonomous system.

## Mapping AS num to CDN site

The following map enables us to map ASes to cdn sites, again with a map:
<pre>
map $my_geoip_org $cdn_site {
  default     cdn;
  include       /etc/nginx/geocdn/as-to-site.conf;
}
</pre>

Where `as-to-site.conf` contains

<pre>
AS137       cdnmi;
AS3269      cdnrm;
</pre>

Note that `$cdn_site` will be used to redirect to `$cdn_site.mirror.garr.it`.

## Actual redirection

Redirection should happen only for defined request URIs and only if the
request comes from a client, not a CDN cache. So we define a variable to
distinguish clients from caches:

<pre>
geo $frontend {
  default C;
  193.206.139.32/28 P;
  193.206.140.32/28 P;
}
</pre>

We only have to decide which URLs should be redirected to the CDN:
<pre>
map $request_uri $uri_for_redirection {
        default $request_uri;
        include /etc/nginx/geocdn/redirections.conf;
}
</pre>

`redirections.conf` maps every URL that should be redirected to the string OK

Redirections happen in a `server {…}` block 
<pre>
set $redirect_to_cdn "$frontend$uri_for_redirection";
if ($redirect_to_cdn ~ "^COK" ) {
  rewrite ^ http://$cdn_site.mirror.garr.it/mirror2$request_uri
  break;
}
</pre>

In our example request coming from a client for `/mirrors/test/` will be
mapped to  `$cdn_site.mirror.garr.it/mirror2/mirrors/test`.
