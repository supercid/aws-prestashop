#!/bin/bash -x

cd /var/www/html || exit
source "env/.env.$ENVIRONMENT_NAME"
export

IS_INSTALLED=$(mysql -h"${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -D "${MYSQL_DATABASE}" -Bse 'SELECT id_configuration FROM ps_configuration WHERE name = "PS_SHOP_DOMAIN" AND value = "'"${VIRTUAL_HOST}"'"')

# shellcheck disable=SC2071
if [ ! "$IS_INSTALLED" > 0 ]; then
  cd /var/www/html/install || exit

  php index_cli.php \
    --step=all \
    --language=en \
    --base_uri=/ \
    --domain="${VIRTUAL_HOST}" \
    --db_server="${MYSQL_HOST}" \
    --db_user="${MYSQL_USER}" \
    --db_password="${MYSQL_PASSWORD}" \
    --email="${ADMIN_EMAIL}" \
    --password="${ADMIN_PASSWORD}" \
    --db_create="${DB_CREATE}" \
    --db_clear="${DB_CLEAR}" \
    --newsletter=0 \
    --send_email=0

  cd /var/www/html/ && rm -rf install && mv admin adminn0st0

  mysql -h"${MYSQL_HOST}" -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" \
        -D "${MYSQL_DATABASE}" \
        -Bse 'UPDATE ps_configuration SET value = 0 WHERE name = "PS_CANONICAL_REDIRECT"; UPDATE ps_configuration SET value = 0 WHERE name = "PS_SSL_ENABLED"; INSERT INTO ps_configuration (name,value) VALUES ("PS_SSL_ENABLED_EVERYWHERE","0");'
  
  # Install Prestashop Nosto Extension
  git clone https://github.com/nosto/nosto-prestashop /var/www/html//modules/nostotagging
  cd /var/www/html/modules/nostotagging && composer install --no-dev
  
  cd /var/www/html/ || exit
  bin/console prestashop:module install nostotagging

  bin/console doctrine:query:sql 'UPDATE ps_configuration SET value = 2 WHERE name = "PS_MAIL_METHOD"'

  # clean-up EFS
  rm -rf /mnt/img/*.*
  rm -rf /mnt/modules/*.*
  rm -rf /mnt/cache/*.*
  rm -rf /mnt/theme/*.*
  rm -rf /mnt/app/*.*
  rm -rf /mnt/override/*.*
  rm -rf /mnt/config/*.*

  cp -r img/* /mnt/img
  cp -r modules/* /mnt/modules
  cp -r cache/* /mnt/cache
  cp -r theme/* /mnt/theme
  cp -r app/* /mnt/app
  cp -r override/* /mnt/override
  cp -r config/* /mnt/config
fi
rm -rf img modules cache theme app override config

cp -r /mnt/img . #img
cp -r /mnt/modules . #modules
cp -r /mnt/cache . #cache
cp -r /mnt/theme . #theme
cp -r /mnt/app . #app
cp -r /mnt/override . #override
cp -r /mnt/config . #config

chown -R www-data:www-data /var/www/html/

apache2-foreground
