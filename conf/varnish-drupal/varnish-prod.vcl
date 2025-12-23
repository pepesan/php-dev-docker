###############################################################################################
### Varnish 4.x+ configuration for Drupal (anonymous caching + static assets)               ###
###############################################################################################

# UPDATED for Drupal use-case (based on the original WordPress/Joomla template)

vcl 4.0;

import std;

backend default {
    .host = "nginx";
    .port = "80";
}

sub vcl_recv {

    # blackfire passthrough (same behavior)
    if (req.http.X-Blackfire-Query) {
        if (req.esi_level > 0) {
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

    # Setting http headers for backend (keep same style)
    set req.http.X-Forwarded-For = client.ip;
    set req.http.X-Forwarded-Proto = "https";
    set req.http.x-clientip = client.ip;
    set req.http.x-serverip = server.ip;
    set req.http.x-localip = local.ip;
    set req.http.x-remoteip = remote.ip;

    # httpoxy
    unset req.http.proxy;

    # Normalize query arguments (Drupal safe)
    set req.url = std.querysort(req.url);

    # Non-RFC2616 or CONNECT
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

    # Only cache GET/HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # === URL manipulation ===
    # Remove common tracking params
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # === Generic cookie manipulation ===
    # Remove has_js (Drupal used to set this; safe to strip)
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Remove Google Analytics cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gid=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

    # Remove DoubleClick cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");

    # Remove AddThis cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");

    # Remove a ";" prefix in the cookie if present
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

    # Empty cookie header?
    if (req.http.Cookie ~ "^\s*$") {
        unset req.http.Cookie;
    }

    # Custom logged-in header convention (if your backend sets it)
    if (req.http.X-Logged-In == "False" && req.method != "POST") {
        unset req.http.Cookie;
    }

    # === DO NOT CACHE ===
    # Authorization/authentication
    if (req.http.Authorization || req.http.Authenticate) {
        set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Drupal: logged-in / session cookies
    # - SESS* / SSESS* => authenticated session
    # - (optional) cookie "no_cache" if you use it as a bypass toggle
    if (req.http.Cookie ~ "(^|;\s*)(SESS|SSESS)[A-Za-z0-9]+=" || req.http.Cookie ~ "(^|;\s*)no_cache=") {
        set req.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        set req.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        set req.http.Pragma = "no-cache";
        return (pass);
    }

    # Drupal: paths that should not be cached (admin, login, maintenance, install/update, etc.)
    if(
        req.url ~ "^/user" ||
        req.url ~ "^/user/" ||
        req.url ~ "^/admin" ||
        req.url ~ "^/admin/" ||
        req.url ~ "^/core/" ||
        req.url ~ "^/update\.php" ||
        req.url ~ "^/install\.php" ||
        req.url ~ "^/cron" ||
        req.url ~ "^/batch" ||
        req.url ~ "^/system/files" ||
        req.url ~ "^/comment/reply" ||
        req.url ~ "^/file/" ||
        req.url ~ "^/media/" ||
        req.url ~ "^/session/token"
    ) {
        return (pass);
    }

    # Don't cache ajax requests (Drupal endpoints)
    if(
        req.http.X-Requested-With == "XMLHttpRequest" ||
        req.url ~ "/ajax" ||
        req.url ~ "/views/ajax" ||
        req.url ~ "/big_pipe" ||
        req.url ~ "nocache"
    ) {
        return (pass);
    }

    # === STATIC FILES ===
    if (req.http.Accept-Encoding) {
        if (req.url ~ "\.(jpg|jpeg|png|gif|gz|tgz|bz2|tbz|mp3|ogg|swf)$") {
            unset req.http.Accept-Encoding;
        } elseif (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elseif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    # Static assets: strip cookies and cache
    if (req.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|ogg|ogm|opus|otf|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }

    return (hash);
}

sub vcl_backend_response {

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

    # Drupal dynamic/secure paths (mirror of vcl_recv)
    if(
        bereq.url ~ "^/user" ||
        bereq.url ~ "^/user/" ||
        bereq.url ~ "^/admin" ||
        bereq.url ~ "^/admin/" ||
        bereq.url ~ "^/core/" ||
        bereq.url ~ "^/update\.php" ||
        bereq.url ~ "^/install\.php" ||
        bereq.url ~ "^/cron" ||
        bereq.url ~ "^/batch" ||
        bereq.url ~ "^/system/files" ||
        bereq.url ~ "^/comment/reply" ||
        bereq.url ~ "^/file/" ||
        bereq.url ~ "^/media/" ||
        bereq.url ~ "^/session/token"
    ) {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Authorization/authentication
    if (
        bereq.http.Authorization ||
        bereq.http.Authenticate
    ) {
        set beresp.http.Cache-Control = "private, max-age=0, no-cache, no-store";
        set beresp.http.Expires = "Mon, 01 Jan 2001 00:00:00 GMT";
        set beresp.http.Pragma = "no-cache";
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Ajax responses should not be cached
    if (beresp.http.X-Requested-With == "XMLHttpRequest" || bereq.url ~ "nocache" || bereq.url ~ "/ajax" || bereq.url ~ "/views/ajax" || bereq.url ~ "/big_pipe") {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache backend response to posted requests
    if (bereq.method == "POST") {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Ok, cacheable: clean headers
    if (beresp.http.X-Logged-In == "False" && bereq.method != "POST") {
        unset beresp.http.Set-Cookie;
    }

    unset beresp.http.etag;
    unset beresp.http.Pragma;

    # Allow stale content if backend is down
    set beresp.grace = 12h;

    # Default TTL
    set beresp.ttl = 180s;

    # Static files: stream and drop cookies
    if (bereq.url ~ "^[^?]*\.(7z|avi|bmp|bz2|css|csv|doc|docx|eot|flac|flv|gif|gz|ico|jpeg|jpg|js|less|mka|mkv|mov|mp3|mp4|mpeg|mpg|odt|ogg|ogm|opus|otf|pdf|png|ppt|pptx|rar|rtf|svg|svgz|swf|tar|tbz|tgz|ttf|txt|txz|wav|webm|webp|woff|woff2|xls|xlsx|xml|xz|zip)(\?.*)?$") {
        unset beresp.http.set-cookie;
        set beresp.do_stream = true;
    }

    # Normalize Cache-Control
    if (beresp.http.Cache-Control !~ "max-age" || beresp.http.Cache-Control ~ "max-age=0" || beresp.ttl < 180s) {
        set beresp.http.Cache-Control = "public, max-age=180, stale-while-revalidate=360, stale-if-error=43200";
    }

    return (deliver);
}

sub vcl_deliver {

    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }

    return (deliver);
}
