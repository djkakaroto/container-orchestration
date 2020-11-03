#!/bin/bash

source /usr/local/bin/co-configure/functions.sh

function_print_banner "TOOLS";
cat /etc/os-release && \
    set -e; apt-get -qq update; apt-get install -qq -y --no-install-recommends apt-utils iputils-ping procps && \
    apt-get install -qq -y git unzip zlib1g-dev libpng-dev libjpeg-dev gettext-base libxml2-dev libzip-dev && \
    apt-get install -qq -y curl libmcrypt-dev default-mysql-client libicu-dev libpq-dev;

function_print_banner "Pickle";
wget https://github.com/FriendsOfPHP/pickle/releases/latest/download/pickle.phar && chmod +x pickle.phar && mv pickle.phar /usr/local/bin/pickle;

function_print_banner "LIBS";
apt-get install -qq -y libcurl4-openssl-dev pkg-config libssl-dev telnet vim netcat libonig-dev librabbitmq-dev;

function_docker-php-ext-configure intl;

function_print_banner "GD";
docker-php-ext-configure gd --with-jpeg=/usr;

function_docker-php-ext-install intl soap zip bcmath sockets exif fileinfo pdo pdo_mysql pdo_pgsql calendar;

function_print_banner "APC";
function_pecl_install apcu && function_docker-php-ext-enable apcu &&\
    function_pecl_install mongodb && function_docker-php-ext-enable mongodb && \
    function_pecl_install redis && function_docker-php-ext-enable redis && \
    function_docker-php-ext-install gd mysqli opcache ctype json xmlwriter;

function_print_banner "AMQP";
    function_pecl_install amqp && \
    function_docker-php-ext-enable amqp;

function_end_build

function_print_banner "Configure unix user";
usermod --shell /bin/bash www-data && \
    usermod --home /var/www/app www-data && \
    useradd -u 1001 -M docker && \
    usermod -a -G docker www-data && \
    usermod -a -G www-data docker && \
    useradd -u 1000 -M rkt && \
    usermod -a -G rkt www-data && \
    usermod -a -G www-data rkt;

function_print_banner "Prepare Composer";
# https://getcomposer.org/download/
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c31c1e292ad7be5f49291169c0ac8f683499edddcfd4e42232982d0fd193004208a58ff6f353fde0012d35fdd72bc394') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

mv -v composer.phar /usr/local/bin/composer; chmod +x /usr/local/bin/composer;

#INFO
php -i | grep version > ~/php-module-versions;