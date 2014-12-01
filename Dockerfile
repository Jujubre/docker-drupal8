# Dockerizing Drupal 8.0b3: docker file to build drupal 8 images
# Drupal requirement: https://api.drupal.org/api/drupal/core!INSTALL.txt/8
#   Need:
#      php >= 5.4.5
#      Nginx >= 1.1 (based image)
#      MariaDB >= 5.1.44

#################################
#### phusion/baseimage
# Format: FROM    repository[:version]
FROM phusion/baseimage:0.9.15

# Format: MAINTAINER Name <email@addr.ess>
MAINTAINER Jujubre <jujubre+docker@gmail.com>

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh
RUN /usr/sbin/enable_insecure_key

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]


# update ubuntu
RUN add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get upgrade -y

#################################
#### Install mariadb
RUN apt-get install -y mariadb-server
RUN \
    sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
    echo "mysqld_safe --log-error=/var/log/mysql/error.log --skip-syslog &" > /tmp/config && \
    echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
    echo "mysql -e 'CREATE DATABASE data;'" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON data.* TO \"data\"@\"%\" IDENTIFIED BY \"data1212\" WITH GRANT OPTION;'" >> /tmp/config && \
    bash /tmp/config && \
    rm -f /tmp/config

#################################
#### isntall nginx 
RUN apt-get install -y nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf 

# configure nginx
RUN rm -f /etc/nginx/sites-enabled/*
ADD sites-enabled/* /etc/nginx/sites-enabled/

#################################
#### Install php5
RUN apt-get install -y php5-cli \
        php5-mysql \
        php5-fpm \
        php5-gd \
        php5-xdebug
RUN echo "cgi.fix_pathinfo = 0;" >> /etc/php5/fpm/php.ini

#################################
#### drush
# Install composer
RUN \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
# and drush
RUN \
    composer global require drush/drush:dev-master && \
    ln -sf /root/.composer/vendor/drush/drush/drush /usr/bin/drush

#################################
#### Install drupal
RUN drush dl drupal-8.0.0-beta3 \
    --drupal-project-rename=drupal8 \
    --destination=/srv
WORKDIR /srv/drupal8
RUN service mysql start && \
    drush site-install standard \
    -y \
    --db-url='mysql://data:data1212@localhost/data' \
    --site-name=drupal8 \
    --account-name=admin \
    --account-pass=drupal1212 && \
    service mysql stop
RUN chown -R www-data:www-data /srv/drupal8 && \
    chmod -R a+w /srv/drupal8/sites/default

#################################
#### Define default command.
# CMD \
#     service ssh start && \
#     service mysql start && \
#     service php5-fpm start && \
#     nginx

#################################
# add services for autostart
RUN mkdir /etc/service/nginx
ADD runit/nginx /etc/service/nginx/run
RUN mkdir /etc/service/mysqld
ADD runit/mysqld /etc/service/mysqld/run
RUN mkdir /etc/service/php5-fpm
ADD runit/php5-fpm /etc/service/php5-fpm/run

#################################
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#################################
#### Expose ports.
EXPOSE 80
EXPOSE 22