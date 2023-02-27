FROM ubuntu:22.04
MAINTAINER Zinc <team@zinc.io>

USER root

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu jammy main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu jammy-security main universe\n" >> /etc/apt/sources.list

#========================
# Packages
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    build-essential \
    squid \
    apache2-utils \
    bzip2 \
    ca-certificates \
    runit \
    sudo \
    unzip \
    wget \
    curl \
    nano \
    vim-nox \
    tzdata \
    locales \
    gnupg \
    stunnel4 \
    net-tools \
    iputils-ping \
    s3cmd \
  && apt-get -qqy dist-upgrade \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean

#=====
# dumb-init trivial PID 1 for Zombie reaping
#=====
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64.deb \
  && dpkg -i dumb-init_*.deb \
  && rm dumb-init_*.deb

#=====
# Timezone
#=====
ENV TZ "US/Eastern"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#=================
# Locale settings
#=================
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend noninteractive locales

#=================
# Install microsocks
#=================
RUN wget -O /tmp/microsocks.zip https://github.com/rofl0r/microsocks/archive/master.zip \
  && cd /tmp \
  && unzip microsocks.zip \
  && cd /tmp/microsocks-master \
  && make \
  && make install \
  && cd / \
  && rm /tmp/microsocks.zip /tmp/microsocks-master -r

#===============
# Configure
#===============
COPY squid.conf /etc/squid/squid.conf
COPY socks5-stunnel.conf /etc/stunnel/socks5-stunnel.conf

#==============
# Set up runit services
#==============
# squid
RUN mkdir -p /etc/service/squid \
    && /bin/bash -c "echo -e '"'#!/bin/bash\nexec /usr/sbin/squid --foreground -YC\n'"' > /etc/service/squid/run" \
    && chmod +x /etc/service/squid/run
# microsocks
RUN mkdir -p /etc/service/microsocks \
    && /bin/bash -c "echo -e '"'#!/bin/bash\nexec /usr/local/bin/microsocks -i 127.0.0.1 -p 1080\n'"' > /etc/service/microsocks/run" \
    && chmod +x /etc/service/microsocks/run
# stunnel
RUN mkdir -p /etc/service/stunnel \
    && /bin/bash -c "echo -e '"'#!/bin/bash\nexec /usr/bin/stunnel /etc/stunnel/socks5-stunnel.conf\n'"' > /etc/service/stunnel/run" \
    && chmod +x /etc/service/stunnel/run

# Health check: run the health_check.sh script every 30 seconds
HEALTHCHECK --interval=30s --timeout=5s CMD /opt/bin/health_check.sh

#=====
# Expose stunnel and squid ports
#=====
EXPOSE 5088
EXPOSE 8443

#=====
# Entry point
#=====
COPY \
  entry_point.sh \
  health_check.sh \
  /opt/bin/
RUN chmod +x /opt/bin/entry_point.sh /opt/bin/health_check.sh

#=====
# Run
#=====
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/bin/entry_point.sh"]
