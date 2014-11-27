#!/bin/bash


chmod -R 777 /var/www/html/drupal8/sites/default

service php5-fpm start && nginx