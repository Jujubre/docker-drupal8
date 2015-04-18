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
git clone ssh://git@132.204.211.203:10022/tdemalliard/docker-drupal8.git
docker build --tag tdemalliard/dupal8 drupal8
```

Run: 
```bash
docker run -d -P --name drupal8 tdemalliard/dupal8
# Get http port on your hosting machine assigned by docker
docker port drupal8
```