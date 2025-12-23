vcl 4.0;

import std;

backend default {
    .host = "nginx";
    .port = "80";
}

sub vcl_recv {

    # LetsEncrypt / ACME passthrough
    if (req.url ~ "^/\.well-known/acme-challenge/") {
        return (pass);
    }

    # Forward client IP
    if (req.restarts == 0) {
        if (req.http.X-Real-IP) {
            set req.http.X-Forwarded-For = req.http.X-Real-IP;
        } else if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # httpoxy
    unset req.http.proxy;

    # Only handle the common methods
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

    # No caching for non-GET/HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Normalize query args (safe for Drupal)
    set req.url = std.querysort(req.url);

    # Strip URL fragment
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Remove common tracking params
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|fbclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    ############################################
    # Drupal: rutas que NO deben cachearse
    ############################################
    if (
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
        req.url ~ "^/cart" ||
        req.url ~ "^/checkout" ||
        req.url ~ "^/user/login" ||
        req.url ~ "^/user/logout"
    ) {
        return (pass);
    }

    # Drupal: endpoints AJAX / dinámicos
    if (
        req.http.X-Requested-With == "XMLHttpRequest" ||
        req.url ~ "/ajax" ||
        req.url ~ "/views/ajax" ||
        req.url ~ "/big_pipe" ||
        req.url ~ "/session/token"
    ) {
        return (pass);
    }

    ############################################
    # Cookies: limpiar lo que no afecta a anónimo
    ############################################

    # Quita cookies típicas de analítica
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gid=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__gads=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuv.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Drupal: cookies que indican sesión/login o variación
    # - SESS / SSESS: sesión autenticada
    # - drupal_user / Drupal.visitor.* (depende de config)
    # - nocache: cookie de bypass (si la usas)
    if (req.http.Cookie ~ "(^|;\s*)(SESS|SSESS)[a-zA-Z0-9]+=") {
        return (pass);
    }

    # Si hay Authorization: no cachear
    if (req.http.Authorization || req.http.Authenticate) {
        return (pass);
    }

    # Si tras limpiar cookies queda vacío, quítalas y permite cache
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");
    if (req.http.Cookie ~ "^\s*$") {
        unset req.http.Cookie;
    }

    ############################################
    # Estáticos: cache fuerte y sin cookies
    ############################################
    if (req.url ~ "^[^?]*\.(css|js|jpg|jpeg|png|gif|ico|svg|svgz|webp|woff|woff2|ttf|eot|pdf|zip|xml|txt)(\?.*)?$") {
        unset req.http.Cookie;
        return (hash);
    }

    return (hash);
}

sub vcl_backend_response {

    # No cachear errores de backend
    if (
        beresp.status == 500 ||
        beresp.status == 502 ||
        beresp.status == 503 ||
        beresp.status == 504
    ) {
        return (abandon);
    }

    # Si el backend marca explícitamente privado/no-store, respétalo
    if (beresp.http.Cache-Control ~ "(?i)(private|no-cache|no-store)" || beresp.http.Pragma ~ "no-cache") {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # No cachear Set-Cookie (normalmente implica sesión/variación)
    if (beresp.http.Set-Cookie) {
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Estáticos: TTL largo
    if (bereq.url ~ "^[^?]*\.(css|js|jpg|jpeg|png|gif|ico|svg|svgz|webp|woff|woff2|ttf|eot|pdf|zip|xml|txt)(\?.*)?$") {
        set beresp.ttl = 7d;
        set beresp.grace = 12h;
        return (deliver);
    }

    # TTL por defecto para HTML anónimo
    # Ajusta si quieres (por ejemplo 180s como tu WP)
    if (beresp.ttl < 180s) {
        set beresp.ttl = 180s;
    }

    # Permite servir stale si el backend cae
    set beresp.grace = 12h;

    # Normaliza Cache-Control si el backend no lo pone bien
    if (beresp.http.Cache-Control !~ "max-age" || beresp.http.Cache-Control ~ "max-age=0") {
        set beresp.http.Cache-Control = "public, max-age=180, stale-while-revalidate=360, stale-if-error=43200";
    }

    # Limpia headers poco útiles para caching
    unset beresp.http.Pragma;
    unset beresp.http.ETag;

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
