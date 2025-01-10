FROM ubuntu:24.04 AS add-apt-repositories

# Install required tools
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y curl gnupg

# Add the Webmin GPG key and repository
RUN curl -fsSL https://www.webmin.com/jcameron-key.asc | gpg --dearmor -o /usr/share/keyrings/webmin-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/webmin-archive-keyring.gpg] http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list

FROM ubuntu:24.04

LABEL maintainer="sameer@damagehead.com"

ENV BIND_USER=bind \
    BIND_VERSION=9.18.30-0ubuntu0.24.04.1 \
    WEBMIN_VERSION=2.202 \
    DATA_DIR=/data

COPY --from=add-apt-repositories /usr/share/keyrings/webmin-archive-keyring.gpg /usr/share/keyrings/webmin-archive-keyring.gpg
COPY --from=add-apt-repositories /etc/apt/sources.list.d/webmin.list /etc/apt/sources.list.d/webmin.list

RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      bind9=1:${BIND_VERSION}* bind9-host=1:${BIND_VERSION}* dnsutils \
      webmin=${WEBMIN_VERSION}* \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 53/udp 53/tcp 10000/tcp

ENTRYPOINT ["/sbin/entrypoint.sh"]

CMD ["/usr/sbin/named"]
