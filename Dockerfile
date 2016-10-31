FROM debian:8.2
MAINTAINER Speed03 <infinity.speed03@gmail.com>

RUN apt-get update&&apt-get upgrade -y
RUN apt-get install apt-utils -y
RUN apt-get install supervisor -y
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y slapd
RUN apt-get install wget -y
RUN apt-get install phpldapadmin -y
RUN apt-get install ldap-utils && apt-get install vim -y
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install courier-ldap -y

ENV LDAP_PASSWORD password
ENV LDAP_ORGANISATION Inc.
ENV LDAP_DOMAIN example.com
ENV LDAP_SERVERNAME "My LDAP server"

RUN echo "[supervisord]" > /etc/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:httpd]" >> /etc/supervisord.conf && \
    echo "command=/usr/sbin/apache2ctl -D FOREGROUND" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:init]" >> /etc/supervisord.conf && \
    echo "command=/root/slapd/init.sh" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:slapd]" >> /etc/supervisord.conf && \
    echo "command=/etc/init.d/slapd start" >> /etc/supervisord.conf

EXPOSE 389
EXPOSE 80

VOLUME ["/var/lib/ldap"]

RUN mkdir /root/slapd/
ADD init.sh /root/slapd/
ADD memberof_config.ldif /root/slapd/
ADD refint1.ldif /root/slapd/
ADD refint2.ldif /root/slapd/

CMD ["/usr/bin/supervisord"]
