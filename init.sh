#!/bin/bash

set -eu

status () {
	echo "---> ${@}" >&2
}

set -x

if [ ! -e /var/lib/ldap/docker_bootstrapped ]; then
	status "configuring slapd for first run"

cat <<EOF | debconf-set-selections
slapd slapd/password2 password ${LDAP_PASSWORD}
slapd slapd/password1 password ${LDAP_PASSWORD}
slapd slapd/internal/generated_adminpw password ${LDAP_PASSWORD}
slapd slapd/internal/adminpw password ${LDAP_PASSWORD}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANISATION}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

dpkg-reconfigure -f noninteractive slapd

touch /var/lib/ldap/docker_bootstrapped


# Configure phpldapadmin
DC='dc='$(echo ${LDAP_DOMAIN} | cut -d "." -f 1)',dc='$(echo ${LDAP_DOMAIN} | cut -d "." -f 2)
sed -i "s/\(\$servers->setValue('server','name','\)\(.*\)\(');\)$/\1${LDAP_SERVERNAME}\3/g" /etc/phpldapadmin/config.php
sed -i "s/\(\$servers->setValue('server','base',array('\)\(.*\)\('));\)$/\1${DC}\3/g" /etc/phpldapadmin/config.php
sed -i "s/\(\$servers->setValue('login','bind_id','\)\(.*\)\(');\)$/\1cn=admin,${DC}\3/g" /etc/phpldapadmin/config.php
sed -i "s/\(\$servers->setValue('login','bind_pass','\)\(.*\)\(');\)$/\1${LDAP_PASSWORD}\3/g" /etc/phpldapadmin/config.php

else
	status "found already-configured slapd"
fi

status "starting slapd"
set -x

pkill slapd
/etc/init.d/slapd start
