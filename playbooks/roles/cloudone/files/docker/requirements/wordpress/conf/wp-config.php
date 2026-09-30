<?php

define('DB_NAME', '__DB_NAME__');
define('DB_USER', '__DB_USER__');
define('DB_PASSWORD', '__DB_PASSWORD__');
define('DB_HOST', '__DB_HOST__');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('FS_METHOD', 'direct');

define('WP_REDIS_HOST', getenv('REDIS_HOST'));
define('WP_REDIS_PORT', getenv('REDIS_PORT'));

if (!defined('ABSPATH')) {
	define('ABSPATH', __DIR__.'/');
}

require_once ABSPATH.'wp-settings.php';
