#!/bin/bash

set -eu

status () {
	echo "---> ${@}" >&2
}

set -x


# Forbid anonymous access
changeAccess () {
cd /root/slapd/

DC=$1

cat > changeAccess.ldif << EOF
dn: olcDatabase={1}hdb,cn=config 
changetype: modify
delete: olcAccess
-
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymous auth by dn="cn=admin,$DC" write by * none
-
add: olcAccess
olcAccess: {1}to dn.base="" by * read
-
add: olcAccess
olcAccess: {2}to * by self write by dn="cn=admin,$DC" write by * none
-
EOF

pkill slapd
service slapd start

ldapmodify -c -Y EXTERNAL -H ldapi:/// -f changeAccess.ldif
}

configMail () {
	cp /usr/share/doc/courier-authlib-ldap/authldap.schema /etc/ldap/schema
	
	mkdir /root/ldapConfig

	cat > /root/ldapConfig/schemaInclude.conf << EOF
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/nis.schema
include /etc/ldap/schema/inetorgperson.schema
include /etc/ldap/schema/authldap.schema
EOF

FIRSTLINE=$(grep -n "^#.*mailhost" /etc/ldap/schema/authldap.schema  | cut -d ":" -f 1)
NBLINES=$(cat /etc/ldap/schema/authldap.schema | wc -l)
head -n $(($FIRSTLINE-1)) /etc/ldap/schema/authldap.schema > /root/authldap.schema
cat /etc/ldap/schema/authldap.schema | head -n $(($FIRSTLINE+3)) | tail -n 4 | cut -d '#' -f 2 >> /root/authldap.schema
tail -n $(($NBLINES-$FIRSTLINE-3)) /etc/ldap/schema/authldap.schema >> /root/authldap.schema
cp /root/authldap.schema /etc/ldap/schema/authldap.schema

slaptest -f /root/ldapConfig/schemaInclude.conf -F /root/ldapConfig

cd /root/ldapConfig/cn=config/cn=schema

AUTHLDAP=$(ls | grep authldap)

cat $AUTHLDAP | sed -re 's/(cn.+)\{[0-9]\}(.*)$/\1\2/g' | sed -re "s/cn=authldap/cn=authldap,cn=schema,cn=config/g" > /root/$AUTHLDAP

head -n $(($(cat /root/$AUTHLDAP |wc -l)-7)) /root/$AUTHLDAP > $AUTHLDAP

ldapadd -Y EXTERNAL -H ldapi:// -f /root/ldapConfig/cn=config/cn=schema/$AUTHLDAP

apt-get purge -y courier-ldap courier-authlib courier-authlib-ldap courier-base courier-doc
}

configMemberof () {
	cd /root/slapd
	ldapadd -Q -Y EXTERNAL -H ldapi:/// -f memberof_config.ldif
	ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f refint1.ldif
	ldapadd -Q -Y EXTERNAL -H ldapi:/// -f refint2.ldif
}

configBase () {
	cd /root/slapd
cat > basic.ldif <<EOF
dn: ou=groups,$1
objectclass: organizationalUnit
objectclass: top
ou: Groups

dn: ou=people,$1
objectclass: organizationalUnit
objectclass: top
ou: People
EOF

ldapadd -x -D cn=admin,$1 -w ${LDAP_PASSWORD} -f basic.ldif
}

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

changeAccess $DC 
configMail
configMemberof
configBase $DC

else
	status "found already-configured slapd"
fi

status "starting slapd"
set -x

/etc/init.d/slapd stop
/etc/init.d/slapd start

