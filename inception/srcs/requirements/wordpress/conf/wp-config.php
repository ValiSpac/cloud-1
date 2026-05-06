<?php
	define( 'DB_NAME',          getenv("SQL_DATABASE"));
	define( 'DB_USER',          getenv("SQL_USER") );
	define( 'DB_PASSWORD',      getenv("SQL_PASSWORD"));
	define( 'DB_HOST',          getenv("WP_MDB_HOST"). ":3306" );
	define( 'DB_CHARSET',       getenv("SQL_CHARSET"));
	define( 'DB_COLLATE',       getenv("SQL_COOLATE"));
	define( 'AUTH_KEY',         '[s/|B%Eo_i2A0dL/%41Oo:dLjn=8l9q@n<1W-;oRT%3DL>V/M.(C`:JK9Aope|u+');
	define( 'SECURE_AUTH_KEY',  'T+y9S_Vk&m?qFb2J>r+W=99T>]/-}U3.(3,S>v#+#?#B-_w12$J]SRM]qd+JnqWw');
	define( 'LOGGED_IN_KEY',    '[_5H.DVcv5yTT|O-9tMBhu+7GdRC0oIFML<xsv*ro-(!nk>e.o984Pb1eM{Yd}!c');
	define( 'NONCE_KEY',        ')D4[T^A5Yk*Q78T>1yptqEwt%qS1{_4O}1pYiSjHY&>+s-~)+K5-B.t7)f|^LJ+.');
	define( 'AUTH_SALT',        ',=DX+=7ExO=:Z%yPf9`jjci&mPl&GPJjCy!O`u]y11E/3Q>?pLT5,<>J!qKeW/Cj');
	define( 'SECURE_AUTH_SALT', 'PDKo6EX 0+@ay^heh@[?5/oel4e@0zbEi%+;LIJGg8 ;B;`50UN-oqtvo-[%Sno9');
	define( 'LOGGED_IN_SALT',   'X^u+HUqRHiFHI_->;W-brfSjgZ>GpK5K`=9r@Zw[3|B&jD#|tB+2EXn5+ )d)*6^');
	define( 'NONCE_SALT',       'NdbU?hL@@)~+]1h^L-lJ-}cI$3ma*GZ):Wi0J`-nYA y?F_6ftGCqJx^0w`=i?~.');

	$table_prefix = getenv("SQL_PREFIX");

	define( 'WP_DEBUG', true);
	if (!defined('ABSPATH'))
		define('ABSPATH', __DIR__ . "/");

	require_once ABSPATH . 'wp-settings.php';
