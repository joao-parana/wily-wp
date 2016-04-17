
/* Move wp-content directory */
define('WP_CONTENT_DIR', $_SERVER['DOCUMENT_ROOT'] . '/content');
define('WP_CONTENT_URL', 'http://' . $_SERVER['SERVER_NAME'] . '/content');

/* Move plugins directory */
define('WP_PLUGIN_DIR', $_SERVER['DOCUMENT_ROOT'] . '/plugins' );
define('WP_PLUGIN_URL', 'http://' . $_SERVER['SERVER_NAME'] . '/plugins');

/* Move WordPress Upload directory */
define( 'UPLOADS', 'uploads' );

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
  define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
