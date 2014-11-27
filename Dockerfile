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

#### isntall nginx + update all sources
RUN \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf

#### configure nginx for drupal
RUN rm -f /etc/nginx/sites-enabled/*
ADD sites-enabled/* /etc/nginx/sites-enabled/

### configure ssh login
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server


#### Install mariadb
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server
RUN \
    sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
    echo "mysqld_safe --log-error=/var/log/mysql/error.log --skip-syslog &" > /tmp/config && \
    echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
    echo "mysql -e 'CREATE DATABASE drupal8;'" >> /tmp/config && \
    echo "mysql -e 'GRANT ALL PRIVILEGES ON drupal8.* TO \"drupal8\"@\"%\" IDENTIFIED BY \"drupal1212\" WITH GRANT OPTION;'" >> /tmp/config && \
    bash /tmp/config && \
    rm -f /tmp/config

#### Install php5
RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y php5-cli \
        php5-mysql \
        php5-fpm \
        php5-gd \
        php5-xdebug

#### drush
# Install composer
RUN \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer
# and drush
RUN \
    composer global require drush/drush:dev-master && \
    ln -sf /root/.composer/vendor/drush/drush/drush /usr/bin/drush

#### Install drupal
RUN drush dl drupal-8.0.0-beta3 \
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


### isntall ssh server
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    echo 'root:screencast' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


#### Define default command.
CMD \
    service ssh start && \
    service mysql start && \
    service php5-fpm start && \
    nginx

#### Expose ports.
EXPOSE 80
EXPOSE 22
# EXPOSE 3306
