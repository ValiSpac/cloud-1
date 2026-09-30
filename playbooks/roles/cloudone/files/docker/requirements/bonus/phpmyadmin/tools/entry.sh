#!/bin/bash
set -euo pipefail

CONFIG="/var/www/phpmyadmin/config.inc.php"
BLOWFISH_SECRET=$(head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32)

cat > "$CONFIG" <<EOF
<?php
\$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['host'] = 'mariadb';
\$cfg['Servers'][\$i]['port'] = '3306';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;
\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
EOF

echo "PHPMYADMIN: Starting on port 8080"
exec php -S 0.0.0.0:8080 -t /var/www/phpmyadmin
