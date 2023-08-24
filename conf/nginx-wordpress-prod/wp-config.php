<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'test' );

/** Database username */
define( 'DB_USER', 'test' );

/** Database password */
define( 'DB_PASSWORD', 'test' );

/** Database hostname */
define( 'DB_HOST', 'db' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          'o+ky2St,_c2j,&;4LKqItCq:a;Zu9c/#u3Y5Cw-xImdAN+N1;)%=^3(d-GWX}nU[' );
define( 'SECURE_AUTH_KEY',   ':P(lZsf.+vREqM`Z7X+x} Tnj|tQHwMr-E!<J@-OsOXYUvKJs2O#$6CUrkH_`qa9' );
define( 'LOGGED_IN_KEY',     'mqM/^u/w|/(^4v:HH7 7:,SiDBnRc_-6csCHd @^$=]JD~R>@ypD,U|n~g+!>zsP' );
define( 'NONCE_KEY',         'N.AwnSRl>r`,<Us=SIVE_qxy1noI;s$CD.MMQJ1oVxhzDKZyndMy?igj/dI._oO]' );
define( 'AUTH_SALT',         'vc<q1Z}sMC5~Wf(eT@B87~{_KG|Er5SB~M7;xpw_jeH]=H&*L0>gN93S5`l!t.)l' );
define( 'SECURE_AUTH_SALT',  'sSH3^%{ h8 ..8oJARIPF{m&]{.*@#rN;3;S0s+(c9=2%n_@dSx4MkPu{=YKb3Mt' );
define( 'LOGGED_IN_SALT',    ';0=6shh(.=X:=ad:MZ=HkI@17-{NV1783Tnp%&]~V0P0pl)o7]awO_QJ!u!Lly+u' );
define( 'NONCE_SALT',        ':*mW>S/QOJ[VN.y_z`9.5dv&uaH`te=JH:>[q,!yP~E{ g<Gh+!cl[9Ix~J99me8' );
define( 'WP_CACHE_KEY_SALT', '*wyq|nCL?77$Fx&#AoKXR[DRjO`1lD`+p(Al$laKH=a_L@VIO,:K+-Bc,!;lMQK&' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
    define( 'WP_DEBUG', false );
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
# Configuración para evitar el ERR_TOO_MANY_REDIRECT
define('FORCE_SSL_ADMIN', true);

if( strpos($_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false )
    $_SERVER['HTTPS'] = 'on';
else
    $_SERVER['HTTPS'] = 'off';
/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';