#!/bin/bash -x

if [ ! -f /var/www/html/.installed ]; then
  
  until mysql -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -h"${MYSQL_HOST}"; do
    >&2 echo "MySQL is unavailable - sleeping"
    sleep 5
  done
  
  cd /var/www/html/install

  php index_cli.php \
    --step=all \
    --language=en \
    --base_uri=/ \
    --domain=${VIRTUAL_HOST} \
    --db_server=${MYSQL_HOST} \
    --db_user=${MYSQL_USER} \
    --db_password=${MYSQL_PASSWORD} \
    --email=${ADMIN_EMAIL} \
    --password=${ADMIN_PASSWORD} \
    --db_create=0 \
    --db_clear=0 \
    --newsletter=0 \
    --send_email=0

  cd /var/www/html/ && rm -rf install && mv admin adminn0st0

  mysql -h mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
        -D ${MYSQL_DATABASE} \
        -Bse 'UPDATE ps_configuration SET value = 0 WHERE name = "PS_CANONICAL_REDIRECT"; UPDATE ps_configuration SET value = 0 WHERE name = "PS_SSL_ENABLED"; INSERT INTO ps_configuration (name,value) VALUES ("PS_SSL_ENABLED_EVERYWHERE","0");'
  
  # Install Prestashop Nosto Extension
  git clone https://github.com/nosto/nosto-prestashop /var/www/html//modules/nostotagging
  cd /var/www/html/modules/nostotagging && \
    composer install --no-dev
  
  cd /var/www/html/
  bin/console prestashop:module install nostotagging

  bin/console doctrine:query:sql 'UPDATE ps_configuration SET value = 2 WHERE name = "PS_MAIL_METHOD"'

  chown -R www-data:www-data /var/www/html/

  touch .installed
fi

apache2-foreground
