dockerized drupal 8 beta 7 working out of the box, testing purpose.

Versions:
 - dockerfile/ubuntu 14.04
 - php latest
 - nginx latest
 - mariadb latest
 - drush 7 (drush:dev-master)

**drupal login:**
 - username = admin
 - password = drupal1212

Build:
```bash
git clone [....]docker-drupal8.git
cd docker-drupal8
docker build --tag tdemalliard/dupal8 .
```

Run: 
```bash
docker run -d -P --name drupal8 tdemalliard/dupal8
# Get http port on your hosting machine assigned by docker
docker port drupal8
```