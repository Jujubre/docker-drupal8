# Dockerizing Drupal 8.0b3: docker file to build drupal 8 images
# Drupal requirement: https://api.drupal.org/api/drupal/core!INSTALL.txt/8
#   Need:
#      php >= 5.4.5
#      Nginx >= 1.1 (based image)
#      MariaDB >= 5.1.44

# Format: FROM    repository[:version]
FROM dockerfile/ubuntu

# Format: MAINTAINER Name <email@addr.ess>
MAINTAINER Jujubre <jujubre+docker@gmail.com>

#### isntall nginx
RUN \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
#RUN chown -R www-data:www-data /var/lib/nginx

#### Install mariadb
# RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
# RUN \
#     sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
#     echo "mysqld_safe --log-error=/var/log/mysql/error.log --skip-syslog &" > /tmp/config && \
#     echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
#     echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
#     echo "mysql -e 'CREATE DATABASE drupal8;'" >> /tmp/config && \
#     echo "mysql -e 'GRANT ALL PRIVILEGES ON drupal8.* TO \"drupal8\"@\"%\" IDENTIFIED BY \"drupal1212\" WITH GRANT OPTION;'" >> /tmp/config && \
#     bash /tmp/config && \
#     rm -f /tmp/config



#### Install php5
RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y php5-cli \
        php5-mysql \
        php5-fpm \
        php5-gd \
        php5-xdebug

#### Install drupal
# RUN \
#     wget -nv http://ftp.drupal.org/files/projects/drupal-8.0.0-beta3.tar.gz  && \
#     tar xf drupal-8.0.0-beta3.tar.gz && \
#     rm drupal-8.0.0-beta3.tar.gz && \
#     mv drupal-8.0.0-beta3 /srv/drupal8 && \
#     chown -R www-data:www-data /srv/drupal8 && \
#     chmod -R a+w /srv/drupal8/sites/default
RUN echo '<?php phpinfo() ?>' > /var/www/html/phpinfo.php

# configure nginx for drupal
ADD sites-enabled/* /etc/nginx/sites-enabled/

#### Install and configure postfix for sending of emails
RUN \
    DEBIAN_FRONTEND=noninteractive  \
    echo "postfix postfix/mailname string example.com" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    apt-get install -y postfix


#### Install composer and drush
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN composer global require drush/drush:6.*
RUN ln -sf /.composer/vendor/drush/drush/drush /usr/bin/drush

#### Define mountable directories.
VOLUME ["/etc/mysql", "/var/lib/mysql", "/var/log", "/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

#### Define default command.
CMD \
    service mysql start && \
    service php5-fpm start && \
    service nginx start

#### Expose ports.
EXPOSE 80
EXPOSE 443
EXPOSE 3306
