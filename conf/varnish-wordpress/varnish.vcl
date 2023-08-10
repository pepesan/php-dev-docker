###############################################################################################
### The perfect Varnish 4.x+ configuration for Joomla, WordPress & other CMS based websites ###
###############################################################################################

######################
#
# UPDATED on July 9th, 2018
#
# Configuration Notes:
# 1. Default dynamic content caching set to 180s.
#    Do a search for "180" and replace with the new value in seconds.
#    Stale cache is served for up to 12 hours.
# 2. Make sure you update the "backend default { ... }" section with the correct IP and port
#
######################

# Varnish Reference:
# See the VCL chapters in the Users Guide at https://www.varnish-cache.org/docs/
# and https://www.varnish-cache.org/trac/wiki/VCLExamples for more examples.

# Marker to tell the VCL compiler that this VCL has been adapted to the new 4.0 format
vcl 4.0;

# Imports
import std;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "wp-nginx"; # UPDATE this only if the web server is not on the same machine
    .port = "80";      # UPDATE 8080 with your web server's (internal) port
}

sub vcl_recv {

/*
    # Blocks
    if (req.http.user-agent ~ "^$" && req.http.referer ~ "^$") {
        return (synth(204, "No content"));
    }
    if (req.http.user-agent ~ "(ahrefs|bingbot|domaincrawler|dotbot|mj12bot|semrush)") {
        return (synth(204, "Bot blocked"));
    }
    # If we host multiple domains on a server, here you can list the domains you DO NOT want to cache
    # The first check matches both naked & "www" subdomains. Use the second for non generic subdomains.
    if (
        req.http.host ~ "(www\.)?(domain1.com|domain2.org|domain3.net)" ||
        req.http.host ~ "(subdomain.domain4.tld|othersubdomain.domain5.tld)"
    ) {
        return (pass);
    }
*/
    # blackfire
    if (req.http.X-Blackfire-Query) {
        if (req.esi_level > 0) {
            # ESI request should not be included in the profile.
            # Instead you should profile them separately, each one
            # in their dedicated profile.
            # Removing the Blackfire header avoids to trigger the profiling.
            # Not returning let it go trough your usual workflow as a regular
            # ESI request without distinction.
            unset req.http.X-Blackfire-Query;
        } else {
            return (pass);
        }
    }

    # LetsEncrypt Certbot passthrough
    if (req.url ~ "^/\.well-known/acme-challenge/") {
        return (pass);
    }

    # Forward client's IP to the backend
    if (req.restarts == 0) {
        if (req.http.X-Real-IP) {
            set req.http.X-Forwarded-For = req.http.X-Real-IP;
        } else if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
    # Setting http headers for backend
    #unset req.http.X-Forwarded-For;
  	set req.http.X-Forwarded-For = client.ip;
  	set req.http.X-Forwarded-Proto = "https";
    set req.http.x-clientip = client.ip;
  	set req.http.x-serverip = server.ip;
  	set req.http.x-localip = local.ip;
  	set req.http.x-remoteip = remote.ip;

    # httpoxy
    unset req.http.proxy;

    # Normalize the query arguments (but exclude for WordPress' backend)
    if (req.url !~ "wp-admin") {
        set req.url = std.querysort(req.url);
    }

    # Non-RFC2616 or CONNECT which is weird.
    if (
        req.method != "GET" &&
        req.method != "HEAD" &&
        req.method != "PUT" &&
        req.method != "POST" &&
        req.method != "TRACE" &&
        req.method != "OPTIONS" &&
        req.method != "DELETE"
    ) {
        return (pipe);
    }

    # We only deal with GET and HEAD by default
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # === URL manipulation ===
    # First remove the Google Analytics added parameters, useless for our backend
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip a trailing ? if it exists
    #if (req.url ~ "\?$") {
    #    set req.url = regsub(req.url, "\?$", "");
    #}

    # === Generic cookie manipulation ===
    # Remove the "has_js" cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Remove any Google Analytics based cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

    # Remove DoubleClick offensive cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");

    # Remove the Quant Capital cookies (added by some plugin, all __qca)
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

    # Remove the AddThis cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");

    # Remove the wp-settings-1 cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-1=[^;]+(; )?", "");

    # Remove the wp-settings-time-1 cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "wp-settings-time-1=[^;]+(; )?", "");

    # Remove the wp test cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=[^;]+(; )?", "");

    # Remove a ";" prefix in the cookie if present
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

    # Are there cookies left with only spaces or that are empty?
    if (req.http.cookie ~ "^\s*$") {
        unset req.http.cookie;
    }

    # Check for the custom "X-Logged-In" header (used by K2 and other apps) to identify
    # if the visitor is a guest, then unset any cookie (including session cookies) provided
    # it's not a POST request.
    if(req.http.X-Logged-In == "False" && req.method != "POST") {
        unset req.http.Cookie;
    }

    # === DO NOT CACHE ===
    # Don't cache HTTP authorization/authentication pages and pages with certain headers or cookies
    if (
        req.http.Authorization ||
        req.http.Authenticate ||
        req.http.X-Logged-In == "True" ||
        req.http.Cookie ~ "userID" ||
        req.http.Cookie ~ "joomla_[a-zA-Z0-9_]+" ||
        req.http.Cookie ~ "(wordpress_[a-zA-Z0-9_]+|wp-postpass|comment_author_[a-zA-Z0-9_]+|woocommerce_cart_hash|woocommerce_items_in_cart|wp_woocommerce_session_[a-zA-Z0-9]+)"
    ) {
        set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Exclude the following paths (e.g. backend admins, user pages or ad URLs that require tracking)
    # In Joomla specifically, you are advised to create specific entry points (URLs) for users to
    # interact with the site (either common user logins or even commenting), e.g. make a menu item
    # to point to a user login page (e.g. /login), including all related functionality such as
    # password reset, email reminder and so on.
    if(
        req.url ~ "^/addons" ||
        req.url ~ "^/administrator" ||
        req.url ~ "^/warenkorb" ||
        req.url ~ "^/kasse" ||
        req.url ~ "^/shop" ||
        req.url ~ "^/component/banners" ||
        req.url ~ "^/component/socialconnect" ||
        req.url ~ "^/component/users" ||
        req.url ~ "^/connect" ||
        req.url ~ "^/kontakt" ||
        req.url ~ "^/login" ||
        req.url ~ "^/logout" ||
        req.url ~ "^/kunden-logout" ||
        req.url ~ "^/lost-password" ||
        req.url ~ "^/" ||
        req.url ~ "^/register" ||
        req.url ~ "^/signin" ||
        req.url ~ "^/signup" ||
        req.url ~ "^/wc-api" ||
        req.url ~ "^/wp-admin" ||
        req.url ~ "^/wp-cron.php" ||
        req.url ~ "^/wp-login.php" ||
        req.url ~ "^/wp-json/wc-analytics/admin/notes" ||
        req.url ~ "^\?add-to-cart=" ||
        req.url ~ "^\?wc-api="
    ) {
        #set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Don't cache ajax requests
    if(req.http.X-Requested-With == "XMLHttpRequest" || req.url ~ "nocache") {
        #set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set req.http.Pragma = "no-cache";
        return (pass);
    }

    # === STATIC FILES ===
    # Properly handle different encoding types
    if (req.http.Accept-Encoding) {
      if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf)$") {
        # No point in compressing these
        unset req.http.Accept-Encoding;
      } elseif (req.http.Accept-Encoding ~ "gzip") {
        set req.http.Accept-Encoding = "gzip";
      } elseif (req.http.Accept-Encoding ~ "deflate") {
        set req.http.Accept-Encoding = "deflate";
      } else {
        # unknown algorithm (aka crappy browser)
        unset req.http.Accept-Encoding;
      }
    }

    # Remove all cookies for static files & deliver directly
    if (req.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|ogg|ogm|opus|otf|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }

    return (hash);

}

sub vcl_backend_response {

/*
    # If we host multiple domains on a server, here you can list the domains you DO NOT want to cache
    # The first check matches both naked & "www" subdomains. Use the second for non generic subdomains.
    if (
        bereq.http.host ~ "(www\.)?(domain1.com|domain2.org|domain3.net)" ||
        bereq.http.host ~ "(subdomain.domain4.tld|othersubdomain.domain5.tld)"
    ) {
        set beresp.uncacheable = true;
        return (deliver);
    }
*/

    # Don't cache 50x responses
    if (
        beresp.status == 500 ||
        beresp.status == 502 ||
        beresp.status == 503 ||
        beresp.status == 504
    ) {
        return (abandon);
    }

    # === DO NOT CACHE ===
    # Exclude the following paths (e.g. backend admins, user pages or ad URLs that require tracking)
    # In Joomla specifically, you are advised to create specific entry points (URLs) for users to
    # interact with the site (either common user logins or even commenting), e.g. make a menu item
    # to point to a user login page (e.g. /login), including all related functionality such as
    # password reset, email reminder and so on.
    if(
        bereq.url ~ "^/addons" ||
        bereq.url ~ "^/administrator" ||
        bereq.url ~ "^/warenkorb" ||
        bereq.url ~ "^/kasse" ||
        bereq.url ~ "^/shop" ||
        bereq.url ~ "^/" ||
        bereq.url ~ "^/component/banners" ||
        bereq.url ~ "^/component/socialconnect" ||
        bereq.url ~ "^/component/users" ||
        bereq.url ~ "^/connect" ||
        bereq.url ~ "^/contact" ||
        bereq.url ~ "^/login" ||
        bereq.url ~ "^/logout" ||
        bereq.url ~ "^/lost-password" ||
        bereq.url ~ "^/mein-konto" ||
        bereq.url ~ "^/register" ||
        bereq.url ~ "^/signin" ||
        bereq.url ~ "^/signup" ||
        bereq.url ~ "^/wc-api" ||
        bereq.url ~ "^/wp-admin" ||
        bereq.url ~ "^/wp-cron.php" ||
        bereq.url ~ "^/wp-login.php" ||
        bereq.url ~ "^/wp-json/wc-analytics/admin/notes" ||
        bereq.url ~ "^\?add-to-cart=" ||
        bereq.url ~ "^\?wc-api="
    ) {
        #set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache HTTP authorization/authentication pages and pages with certain headers or cookies
    if (
        bereq.http.Authorization ||
        bereq.http.Authenticate ||
        bereq.http.X-Logged-In == "True" ||
        bereq.http.Cookie ~ "userID" ||
        bereq.http.Cookie ~ "joomla_[a-zA-Z0-9_]+" ||
        bereq.http.Cookie ~ "(wordpress_[a-zA-Z0-9_]+|wp-postpass|comment_author_[a-zA-Z0-9_]+|woocommerce_cart_hash|woocommerce_items_in_cart|wp_woocommerce_session_[a-zA-Z0-9]+)"
    ) {
        set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache ajax requests
    if(beresp.http.X-Requested-With == "XMLHttpRequest" || bereq.url ~ "nocache") {
        #set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        #set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        #set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache backend response to posted requests
    if (bereq.method == "POST") {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Ok, we're cool & ready to cache things
    # so let's clean up some headers and cookies
    # to maximize caching.

    # Check for the custom "X-Logged-In" header to identify if the visitor is a guest,
    # then unset any cookie (including session cookies) provided it's not a POST request.
    if(beresp.http.X-Logged-In == "False" && bereq.method != "POST") {
        unset beresp.http.Set-Cookie;
    }

    # Unset the "etag" header (suggested)
    unset beresp.http.etag;

    # Unset the "pragma" header
    unset beresp.http.Pragma;

    # Allow stale content, in case the backend goes down
    set beresp.grace = 12h;

    # This is how long Varnish will keep cached content
    set beresp.ttl = 180s;

    # Modify "expires" header - https://www.varnish-cache.org/trac/wiki/VCLExampleSetExpires
    #set beresp.http.Expires = "" + (now + beresp.ttl);

    # If your backend server does not set the right caching headers for static assets,
    # you can set them below (uncomment first and change 604800 - which 1 week - to whatever you
    # want (in seconds)
    #if (req.url ~ "\.(ico|jpg|jpeg|gif|png|bmp|webp|tiff|svg|svgz|pdf|mp3|flac|ogg|mid|midi|wav|mp4|webm|mkv|ogv|wmv|eot|otf|woff|ttf|rss|atom|zip|7z|tgz|gz|rar|bz2|tar|exe|doc|docx|xls|xlsx|ppt|pptx|rtf|odt|ods|odp)(\?[a-zA-Z0-9=]+)$") {
    #    set beresp.http.Cache-Control = "public, max-age=604800";
    #}

    if (bereq.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|ogg|ogm|opus|otf|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        unset beresp.http.set-cookie;
        set beresp.do_stream = true;
    }

    # We have content to cache, but it's got no-cache or other Cache-Control values sent
    # So let's reset it to our main caching time (180s as used in this example configuration)
    # The additional parameters specified (stale-while-revalidate & stale-if-error) are used
    # by modern browsers to better control caching. Set these to twice & four times your main
    # cache time respectively.
    # This final setting will normalize cache-control headers for CMSs like Joomla
    # which set max-age=0 even when the CMS' cache is enabled.
    if (beresp.http.Cache-Control !~ "max-age" || beresp.http.Cache-Control ~ "max-age=0" || beresp.ttl < 180s) {
        set beresp.http.Cache-Control = "public, max-age=180, stale-while-revalidate=360, stale-if-error=43200";
    }

    return (deliver);

}

sub vcl_deliver {

/*
    # Send a special header for excluded domains only
    # The if statement can be identical to the ones in the vcl_recv() and vcl_fetch() functions above
    if (
        req.http.host ~ "(www\.)?(domain1.com|domain2.org|domain3.net)" ||
        req.http.host ~ "(subdomain.domain4.tld|othersubdomain.domain5.tld)"
    ) {
        set resp.http.X-Domain-Status = "EXCLUDED";
    }
    # Enforce redirect to HTTPS for specified domains only
    #if (
    #    req.http.host ~ "(subdomain.domain4.tld|othersubdomain.domain5.tld)" &&
    #    req.http.X-Forwarded-Proto !~ "(?i)https"
    #) {
    #    set resp.http.Location = "https://" + req.http.host + req.url;
    #    set resp.status = 302;
    #}
*/
    # Send special headers that indicate the cache status of each web page
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }

    return (deliver);

}