# sealeo/openldap

[hub]: https://hub.docker.com/r/sealeo/openldap/

OpenLDAP 2.4.40 - [Docker Hub](https://hub.docker.com/r/sealeo/openldap/) 

**A docker image to run OpenLDAP with PHPLDAPAdmin**

> OpenLDAP website : [www.openldap.org](http://www.openldap.org/)

# Installation

If you run your container with docker CLI :
```bash
docker run -d -v /home/ldap/data:/var/lib/data -p 389:389 -p 80:80 -e LDAP_PASSWORD=password -e LDAP_ORGANISATION="My LDAP Server" -e LDAP_DOMAIN=mydomain.com -e LDAP_SERVERNAME=MyLDAP --name ldap sealeo/openldap
```

Or if you use *docker-compose*

```yaml
version: '3'
services:
	ldap:
		image: sealeo/openldap
		volumes:
			- /path/ldap/data:/var/lib/ldap
		ports:
			- 389:389
			- 80:80
		environment:
			- LDAP_PASSWORD=password
			- LDAP_ORGANISATION="My LDAP Server"
			- LDAP_DOMAIN=mydomain.com
			- LDAP_SERVERNAME=MyLDAP
			- LDAP_SSL=0
```

# Usage

To add user and group, 2 scripts are available and you can execute with *docker exec* command

## Add user

```bash
docker exec -it ldap add_user

Login? joe
Firstname? Joe
Lastname? Smith
Email? joe@smith.com
Password?

adding new entry "cn=joe,ou=people,dc=mydomain,dc=com"
```

## Add group

```bash
docker exec -it ldap add_group

UID? members

adding new entry "cn=members,ou=groups,dc=mydomain,dc=com"
```

## PHPLDAPadmin

On the port 80, you can access to PHPLDAPadmin to administrate your LDAP.

Your credentials:
```yaml
Login DN: cn=admin,dc=mydomain,dc=com

Password: password
```
The password is *LDAP_PASSWORD* field
