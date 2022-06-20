FROM public.ecr.aws/docker/library/php:7.2-apache-stretch

MAINTAINER Cid Lopes "alannettto@gmail.com"

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PRESTASHOP_VERSION 1.7.6.7
ENV PRESTASHOP_ARCHIVE prestashop_${PRESTASHOP_VERSION}

RUN sed -i "s/Listen 80/Listen 9999/" /etc/apache2/ports.conf
RUN sed -i "s/Listen 443/Listen 9999/" /etc/apache2/ports.conf

RUN apt-get update && \
    apt-get -y -qq install apt-transport-https locales jq zip unzip wget \
        libfreetype6-dev libjpeg-dev libpng-dev mariadb-client \
        libmcrypt-dev libzip-dev libxml2-dev libxslt1-dev libicu-dev \
        vim nano git wget gnupg cron sudo && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    apt-get -y clean && \
    touch /var/log/cron.log

RUN a2enmod rewrite headers expires

# Install PHP extensions & composer
RUN pecl install ast mcrypt-1.0.2 apcu && \
    docker-php-ext-enable ast apcu && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd mysqli pdo_mysql mbstring soap xsl zip opcache bcmath intl pcntl sockets && \
    docker-php-ext-enable mcrypt && \
    php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

RUN echo 'www-data ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY conf/customphp.ini /usr/local/etc/php/conf.d/customphp.ini

RUN cd / && wget https://github.com/PrestaShop/PrestaShop/releases/download/${PRESTASHOP_VERSION}/${PRESTASHOP_ARCHIVE}.zip && \
	cd / && mkdir -m 755 -p /var/www/html/ && \
	cd / && unzip ${PRESTASHOP_ARCHIVE} -d /var/www/html/wrap/ && \
	cd /&& unzip /var/www/html/wrap/prestashop.zip -d /var/www/html// && \
	chown -R www-data:www-data /var/www/html/ && \
    rm -rf /${PRESTASHOP_ARCHIVE}.zip \
    rm -rf /var/www/html/wrap

ADD scripts/init-and-run.sh /usr/local/bin/init-and-run
EXPOSE 9999
CMD ["init-and-run"]
