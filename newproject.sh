#!/bin/bash

RESULT=0
res1=$(date +%s.%N)

clear

# Functions.
resultcount()
{
  RESULT=$1
  RESULT=$(($RESULT+$?))
  echo " --------- Check errors. Erros count: ${RESULT}"
  if [ $RESULT = 1 ]; then
    echo "Exiting..."
    exit 1
  fi
}

createdirectory()
{
  DIRNAME=$1
  mkdir $DIRNAME
  echo "Readme" > $DIRNAME"/README.txt"
}

#Script
echo "==================="
echo "Droptica NewProject"
echo "Created by Droptica - www.droptica.com"
echo "==================="
echo "Starting ..."


if [ "$(id -u)" != "0" ]; then
  echo "Sorry, you are not root."
  echo "Usage: sudo ./newproject.sh";
  exit 1
fi


# Load settings.
source newproject.settings.inc
resultcount $RESULT

echo "Parameters: "
echo "- project_name: ${PROJECTNAME}"
echo "- DB_ROOT_USERNAME: ${DB_ROOT_USERNAME}"
echo "- DB_ROOT_PASS: ${DB_ROOT_PASS}"
echo "- DB_DRUPAL_USERNAME: ${DB_DRUPAL_USERNAME}"
echo "- DB_DRUPAL_PASS: ${DB_DRUPAL_PASS}"
echo "- DB_DRUPAL_DBNAME: ${DB_DRUPAL_DBNAME}"

echo "Checking configuration ..."
if [ -z $PROJECTNAME ]; then echo "PROJECTNAME is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;

if [ -z $DB_ROOT_USERNAME ]; then echo "DB_ROOT_USERNAME is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;
if [ -z $DB_ROOT_PASS ]; then echo "DB_ROOT_PASS is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;

if [ -z $DB_DRUPAL_USERNAME ]; then echo "DB_DRUPAL_USERNAME is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;
if [ -z $DB_DRUPAL_PASS ]; then echo "DB_DRUPAL_PASS is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;
if [ -z $DB_DRUPAL_DBNAME ]; then echo "DB_DRUPAL_DBNAME is empty. Set variable in file newproject.settings.inc. Exiting"; exit 1; fi;


if [ -d "$PROJECTNAME" ]; then
   echo "Directory ${PROJECTNAME} exists!"
  read -p " == Are you sure you want to delete this directory? (y/n)" -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      echo " Removing directory..."
      chmod -R 777 $PROJECTNAME/app/sites/default
      rm -rf $PROJECTNAME
  else
     echo " Exiting"
     exit 1;
  fi
fi

 echo "Create Apache vhost file"
 touch $APACHE_VHOST_FILE

# Create a vhost for jenkins to proxy to port 8080
 echo '<VirtualHost *:80>' > $APACHE_VHOST_FILE
 echo '    ServerName '$APACHE_VHOST_NAME >> $APACHE_VHOST_FILE
 echo '    DocumentRoot '$PROJECT_DIR_APP >> $APACHE_VHOST_FILE
 echo '</VirtualHost>' >> $APACHE_VHOST_FILE
 echo ' ' >> $APACHE_VHOST_FILE

#sudo echo -e "<VirtualHost *:80>\n\tServerName ${APACHE_VHOST_NAME}\n\tDocumentRoot ${PROJECT_DIR_APP}\n</VirtualHost>" > $APACHE_VHOST_FILE

echo "Add entry to /etc/hosts"
 echo -e "127.0.0.1 ${APACHE_VHOST_NAME}" >> $HOSTS_FILE
if [ $CISCO_VPN_INSTALLED = "yes" ];
  then
   cp $HOSTS_FILE $HOSTS_FILE".ac"
fi
sudo service apache2 restart

echo "Drop database if exists ..."
mysql -u$DB_ROOT_USERNAME -p$DB_ROOT_PASS -e "DROP DATABASE IF EXISTS ${DB_DRUPAL_DBNAME};"
resultcount $RESULT

echo "Create database if exists ..."
mysql -u $DB_ROOT_USERNAME -p$DB_ROOT_PASS -e "CREATE DATABASE ${DB_DRUPAL_DBNAME};"
resultcount $RESULT

echo "Create database user ..."
mysql -u $DB_ROOT_USERNAME -p$DB_ROOT_PASS -e "DROP USER '$DB_DRUPAL_USERNAME'@'localhost'"
resultcount $RESULT
mysql -u $DB_ROOT_USERNAME -p$DB_ROOT_PASS  -e "CREATE USER '$DB_DRUPAL_USERNAME'@'localhost' IDENTIFIED BY '$DB_DRUPAL_PASS';"
resultcount $RESULT

mysql -u $DB_ROOT_USERNAME -p$DB_ROOT_PASS  -e "GRANT ALL PRIVILEGES ON ${DB_DRUPAL_DBNAME}.* TO '$DB_DRUPAL_USERNAME'@'localhost';"
mysql -u $DB_ROOT_USERNAME -p$DB_ROOT_PASS  -e "FLUSH PRIVILEGES;"

echo "Create directory: ${PROJECTNAME}"
mkdir $PROJECTNAME
cd $PROJECTNAME

echo "Create project directories.."
createdirectory databases
createdirectory conf
createdirectory other
createdirectory docs
createdirectory scripts

echo "Downloading Drupal to directory app"
drush dl
mv drupal* app

echo "Create files directory"
mkdir app/sites/default/files
echo "Copy settings.php"
cp app/sites/default/default.settings.php app/sites/default/settings.php
echo "Set permissions for files and settings.php"
chmod 777 app/sites/default/files  app/sites/default/settings.php

echo "==== Drush commands"

echo "Drupal site install.."
drush -r $PROJECT_DIR_APP si $DRUPAL_INSTALLATION_PROFILE \
 --db-url=mysql://$DB_DRUPAL_USERNAME:$DB_DRUPAL_PASS@localhost/$DB_DRUPAL_DBNAME \
 --account-name=admin \
 --account-pass=$DRUPAL_SITE_ADMIN_PASS \
 --site-name=$PROJECTNAME \
 --site-mail=$DRUPAL_SITE_ADMIN_MAIL -y

echo "Create module directories.."
mkdir app/sites/all/modules/contrib
mkdir app/sites/all/modules/custom
mkdir app/sites/all/modules/universal
mkdir app/sites/all/modules/dev

echo "Download Zen theme..."
cd app/sites/all/themes
drush dl zen

echo "Download Contrib modules..."
cd ../modules/contrib/
drush dl views ctools context features strongarm token pathauto rules entity feeds transliteration admin_menu diff elysia_cron job_scheduler libraries views_bulk_operations

cd ../dev/
drush dl devel coder hacked  --destination=sites/all/modules/dev

echo "Disable modules..."
drush dis toolbar overlay -y
drush en admin_menu_toolbar admin_devel context_ui strongarm views_ui diff elysia_cron features feeds_ui libraries pathauto token rules_admin transliteration views_bulk_operations -y
cd ../../../../../
mkdir patches
mkdir patches/core
diff -ruN app/cron.php app/sites/all/modules/contrib/elysia_cron/cron.php > patches/core/01_cron_elysia.patch
cp -r app/sites/all/modules/contrib/elysia_cron/cron.php app/cron.php

res2=$(date +%s.%N)
echo "Start time: $res1"
echo "Stop time:  $res2"
echo "Elapsed:    $(echo "$res2 - $res1"|bc )"

if [ $RESULT = 0 ]; then
    exit 0
else
    exit 1
fi

echo "Droptica NewProject end."
echo "================="
