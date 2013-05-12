# newproject.settings.inc

PROJECTNAME=myprojectname
PROJECT_DIR=/home/gbartman/openBIT/www2/"$PROJECTNAME"
PROJECT_DIR_APP=$PROJECT_DIR"/app"

APACHE_VHOST_FILE="/etc/apache2/sites-enabled/"$PROJECTNAME
APACHE_VHOST_NAME="www."$PROJECTNAME".local"

HOSTS_FILE=/etc/hosts

# If Cisco VPN is installed on Ubuntu you have to copy /etc/hosts to /etc/hosts.ac after modifications.
CISCO_VPN_INSTALLED=yes

DB_ROOT_USERNAME=root
DB_ROOT_PASS=rootpassword

DB_DRUPAL_USERNAME=myprojectname_gb
DB_DRUPAL_PASS="123"
DB_DRUPAL_DBNAME="myprojectname_gb"

DRUPAL_INSTALLATION_PROFILE=standard

DRUPAL_SITE_ADMIN_MAIL=admin@example.com

DRUPAL_SITE_ADMIN_PASS=123
