FROM debian:8.2
MAINTAINER Speed03 <infinity.speed03@gmail.com>

RUN apt-get update&&apt-get upgrade -y
RUN apt-get install apt-utils -y
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y slapd
RUN apt-get install wget -y
RUN apt-get install phpldapadmin -y
RUN apt-get install ldap-utils && apt-get install vim -y

ENV LDAP_PASSWORD password
ENV LDAP_ORGANISATION Inc.
ENV LDAP_DOMAIN example.com
ENV LDAP_SERVERNAME "My LDAP server"

EXPOSE 389
EXPOSE 80

VOLUME ["/var/lib/ldap"]

RUN mkdir /root/slapd
ADD init.sh /root/slapd

CMD /root/slapd/init.sh

