# Dockerizing Drupal 8.0b3: docker file to build drupal 8 images
# Drupal requirement: https://api.drupal.org/api/drupal/core!INSTALL.txt/8
#   Need:
#      php >= 5.4.5
#      Nginx >= 1.1 (based image)
#      MariaDB >= 5.1.44

# Format: FROM    repository[:version]
FROM ubuntu:14.04

# Format: MAINTAINER Name <email@addr.ess>
MAINTAINER Jujubre <jujubre+docker@gmail.com>

#################################
#### isntall nginx + update all sources
RUN echo 'Acquire::http { Proxy "http://172.17.42.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy
RUN apt-get install -qy software-properties-common
RUN \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get install -qy nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf

#### configure nginx for drupal
RUN rm -f /etc/nginx/sites-enabled/*
ADD sites-enabled/* /etc/nginx/sites-enabled/

#################################
#### Install mariadb
RUN apt-get install -qy mariadb-server
RUN \
    sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
    echo "mysqld_safe --log-error=/var/log/mysql/error.log --skip-syslog &" > /tmp/config && \
    echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
    echo "mysql -e 'CREATE DATABASE drupal8;'" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON drupal8.* TO \"drupal8\"@\"%\" IDENTIFIED BY \"drupal1212\" WITH GRANT OPTION;'" >> /tmp/config && \
    bash /tmp/config && \
    rm -f /tmp/config

#################################
#### Install php5
RUN apt-get install -qy \
    php5-cli \
    php5-fpm \
    php5-mysql \
    php5-gd

#################################
#### drush
# Install composer
RUN \  
    apt-get install -qy curl && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
# and drush
RUN \
    composer global require drush/drush:dev-master && \
    ln -sf /root/.composer/vendor/drush/drush/drush /usr/bin/drush

#################################
#### Install drupal
RUN drush dl drupal-8.0.0-beta9 \
    --drupal-project-rename=drupal8 \
    --destination=/srv
WORKDIR /srv/drupal8
RUN service mysql start && \
    drush site-install standard \
    -y \
    --db-url='mysql://drupal8:drupal1212@localhost/drupal8' \
    --site-name=drupal8 \
    --account-name=admin \
    --account-pass=drupal1212 && \
    service mysql stop
RUN chown -R www-data:www-data /srv/drupal8 && \
    chmod -R a+w /srv/drupal8/sites/default

#################################
### cleaning
RUN apt-get purge -qy software-properties-common
RUN rm -rf /tmp/*
RUN apt-get clean -y

#################################
#### Define default command.
CMD \
    service mysql start && \
    service php5-fpm start && \
    nginx

#################################
#### Expose ports.
EXPOSE 80