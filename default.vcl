backend mirror3 {
    .host = "193.206.139.34";
    .port = "80";
}

backend mirror2 {
	.host = "193.206.140.37";
	.port = "80";
}

backend mirror1 {
	.host = "193.206.140.34";
	.port = "80";
}


sub vcl_recv {

if (
    req.http.user-agent ~ "^$" || 
    req.http.user-agent ~ "^BTWebClient"
) {
    error 403 "You are banned from this site.  Please contact via a different client configuration if you believe that this is a mistake.";
}


set req.grace = 5m;

remove req.http.Cookie;

# map /request_uris to backend
if (req.url ~ "^/mirror1/")
{
    set req.backend = mirror1;
}
elseif (req.url ~ "^/mirror2/") 
{ 
    set req.backend = mirror2; 
}
elseif (req.url ~ "^/mirror3/")
{
    set req.backend = mirror3;
}
elseif (req.url ~ "^/sf/")
{
    set req.backend = mirror1;
}

# map request host to backend
if (req.http.host == "garr.dl.sourceforge.net")
{
    set req.backend = mirror1;
}

if (req.http.host == "it.archive.ubuntu.com")
{
    set req.backend = mirror2;
}

if (req.http.host == "it.releases.ubuntu.com" )
{
    set req.backend = mirror2;
}

if (req.http.host == "fedora.mirror.garr.it")
{
    set req.backend = mirror1;
}

if (req.http.host == "ooo.mirror.garr.it")
{
    set req.backend = mirror2;
}

if (req.http.host == "mozilla.mirror.garr.it")
{
        set req.backend = mirror3;
}

if (req.http.host == "freerainbowtables.mirror.garr.it")
{
        set req.backend = mirror2;
}

if (req.http.Accept-Encoding) {
    if (req.url ~ "\.(jpg|png|gif|gz|tgz|bz2|tbz|mp3|ogg)$") {
        # No point in compressing these
        remove req.http.Accept-Encoding;
    } elsif (req.http.Accept-Encoding ~ "gzip") {
        set req.http.Accept-Encoding = "gzip";
    } elsif (req.http.Accept-Encoding ~ "deflate") {
        set req.http.Accept-Encoding = "deflate";
    } else {
        # unkown algorithm
        remove req.http.Accept-Encoding;
    }
}

}

sub vcl_miss {
    # rewrite request uri according to uri on backend
	set bereq.url = regsub(req.url,"^/mirror[0-9]/","/");

	if (req.url ~ "^/sf/") {
        set bereq.http.host = "garr.dl.sourceforge.net";
        set bereq.url = regsub(req.url,"^/sf/","/");
	}
	return(fetch);

}

sub vcl_fetch {

  if (req.url ~ "\.(iso|dmg|exe)$") {
     set beresp.ttl = 1d;
  }

if (req.url ~ "(repmod.xml|Release|Release.gpg|Packages.gz|Packages.bz2)$") {
     set beresp.ttl=4h;

}

if (req.url ~ "\.(rti2|mar|gz|rpm|deb|udeb|tar\.gz|tar\.bz2)$" ) {
		set beresp.ttl=8h;
}
set beresp.grace = 10m;

return(deliver);
}


sub vcl_deliver {
        if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
}
