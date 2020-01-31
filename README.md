[Droptica](https://www.droptica.com) NewProject Script

In one command you can create Drupal project with configured Apache vhost, host, MySQL.

Script procedure:
* create Apache vhost file
* add entry to /etc/hosts
* create database and user in database
* create project directory
* download Drupal with Drush
* install Drupal
* download modules (views ctools context features strongarm token pathauto rules entity feeds transliteration admin_menu diff elysia_cron job_scheduler libraries views_bulk_operations)
* download zen theme
* create patch for Elysia Cron module (cron.php file)

Usage:
* go to directory where you want to create project
* copy files newproject.settings.inc and newproject.sh to this directory
* change settings in newproject.settings.inc
* run command: sudo ./newproject.sh

Tested on Ubuntu 12.04 (Apache, MySQL, Drush)

Created by Droptica www.droptica.com
