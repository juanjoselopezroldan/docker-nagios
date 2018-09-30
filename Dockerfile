FROM ubuntu:16.04
MAINTAINER juanjoselopez

ENV NAGIOS_HOME="/opt/nagios" \
    NAGIOS_USER="nagios" \
    NAGIOS_GROUP="nagios" \
    NAGIOS_CMDUSER="nagios" \
    NAGIOS_CMDGROUP="nagios" \
    NAGIOS_FQDN="nagios.nagios.es" \
    NAGIOSADMIN_USER="nagiosadmin" \
    NAGIOSADMIN_PASS="nagiosadmin" \
    APACHE_RUN_USER="nagios" \
    APACHE_RUN_GROUP="nagios" \
    NAGIOS_TIMEZONE="UTC" \
    DEBIAN_FRONTEND="noninteractive" \
    NG_NAGIOS_CONFIG_FILE="/opt/nagios/etc/nagios.cfg" \
    NG_CGI_DIR="/opt/nagios/sbin" \
    NG_WWW_DIR="/opt/nagios/share/nagiosgraph" \
    NG_CGI_URL="/cgi-bin" \
    NAGIOS_BRANCH="nagios-4.3.4" \
    NAGIOS_PLUGINS_BRANCH="release-2.2.1" \
    NRPE_BRANCH="nrpe-3.2.1" \
    MYSQL_USER="nagios" \
    MAIL_RELAY_HOST="[smtp.gmail.com]:587" \
    MAIL_INET_PROTOCOLS="all" \
    MYSQL_PASSWORD="nagios" \
    MYSQL_HOST="mysql" \
    MYSQL_DATABASE="nagios"

RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections  && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections            && \
    echo postfix postfix/mailname string ${NAGIOS_FQDN} | debconf-set-selections             && \
    apt-get update && apt-get install -y    \
        apache2                             \
        apache2-utils                       \
        autoconf                            \
        automake                            \
        bc                                  \
        bsd-mailx                           \
        build-essential                     \
        dnsutils                            \
        fping                               \
        gettext                             \
        git                                 \
        gperf                               \
        iputils-ping                        \
        jq                                  \
        jshon                               \
        ruby                                \
        libapache2-mod-php                  \
        libcache-memcached-perl             \
        libcgi-pm-perl                      \
        libdbd-mysql-perl                   \
        libdbi-dev                          \
        libdbi-perl                         \
        libfreeradius-client-dev            \
        libgd2-xpm-dev                      \
        libgd-gd2-perl                      \
        libjson-perl                        \
        libldap2-dev                        \
        libmysqlclient-dev                  \
        libnagios-object-perl               \
        libnagios-plugin-perl               \
        libnet-snmp-perl                    \
        libnet-snmp-perl                    \
        libnet-tftp-perl                    \
        libnet-xmpp-perl                    \
        libpq-dev                           \
        libredis-perl                       \
        librrds-perl                        \
        libssl-dev                          \
        libswitch-perl                      \
        libwww-perl                         \
        m4                                  \
        netcat                              \
        parallel                            \
        php-cli                             \
        php-gd                              \
        postfix                             \
        python-pip                          \
        rsyslog                             \
        runit                               \
        smbclient                           \
        mysql-client                        \
        snmp                                \
        snmpd                               \
        snmp-mibs-downloader                \
        unzip                               \
        python                              \
        nano                                \
        curl                                \
        mlocate                             \
                                              && \
    apt-get clean && rm -Rf /var/lib/apt/lists/*

RUN apt-get update && apt upgrade -y \
        && apt-get install -y apt-transport-https \
        && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
        && touch /etc/apt/sources.list.d/kubernetes.list \
        && echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list \
        && apt-get update \
        && apt-get install -y kubectl \
        && apt-get clean \
        && curl -o /tmp/kubectl -SL https://storage.googleapis.com/kubernetes-release/release/v1.10.0/bin/linux/amd64/kubectl \
        && chmod +x /tmp/kubectl \
        && mv /tmp/kubectl /usr/local/bin/kubectl

RUN apt-get install lsb -y \
        && export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
        && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
        && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
        && apt-get update && apt-get install -y google-cloud-sdk \
	&& apt-get clean

RUN ( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )                         && \
    ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP ) && \
    ( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )  && \
    ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

RUN cd /tmp                                           && \
    git clone https://github.com/multiplay/qstat.git  && \
    cd qstat                                          && \
    ./autogen.sh                                      && \
    ./configure                                       && \
    make                                              && \
    make install                                      && \
    make clean

RUN cd /tmp                                                                          && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH  && \
    cd nagioscore                                                                    && \
    ./configure                                  \
        --prefix=/opt/nagios                  \
        --exec-prefix=/opt/nagios             \
        --enable-event-broker                    \
        --with-command-user=${NAGIOS_CMDUSER}    \
        --with-command-group=${NAGIOS_CMDGROUP}  \
        --with-nagios-user=${NAGIOS_USER}        \
        --with-nagios-group=${NAGIOS_GROUP}      \
                                                                                     && \
    make all                                                                         && \
    make install                                                                     && \
    make install-config                                                              && \
    make install-commandmode                                                         && \
    make install-webconf                                                             && \
    make clean

RUN cd /tmp                                                                                   && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH  && \
    cd nagios-plugins                                                                         && \
    ./tools/setup                                                                             && \
    ./configure                  \
        --prefix=/opt/nagios  \
                                                                                              && \
    make                                                                                      && \
    make install                                                                              && \
    make clean                                                                                && \
    mkdir -p /usr/lib/nagios/plugins                                                          && \
    ln -sf /opt/nagios/libexec/utils.pm /usr/lib/nagios/plugins

RUN curl -o /opt/nagios/libexec/check_ncpa.py -SL https://raw.githubusercontent.com/NagiosEnterprises/ncpa/v2.0.5/client/check_ncpa.py  && \
    chmod +x /opt/nagios/libexec/check_ncpa.py

RUN cd /tmp                                                                  && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH  && \
    cd nrpe                                                                  && \
    ./configure                                   \
        --with-ssl=/usr/bin/openssl               \
        --with-ssl-lib=/usr/lib/x86_64-linux-gnu  \
                                                                             && \
    make check_nrpe                                                          && \
    cp src/check_nrpe /opt/nagios/libexec/                                && \
    make clean

RUN cd /tmp                                                          && \
    git clone https://git.code.sf.net/p/nagiosgraph/git nagiosgraph  && \
    cd nagiosgraph                                                   && \
    ./install.pl --install                                      \
        --prefix /opt/nagiosgraph                               \
        --nagios-user ${NAGIOS_USER}                            \
        --www-user ${NAGIOS_USER}                               \
        --nagios-perfdata-file /opt/nagios/var/perfdata.log  \
        --nagios-cgi-url /cgi-bin                               \
                                                                     && \
    cp share/nagiosgraph.ssi /opt/nagios/share/ssi/common-header.ssi

RUN cd /opt                                                                         && \
    pip install pymssql                                                             && \
    git clone https://github.com/willixix/naglio-plugins.git     WL-Nagios-Plugins  && \
    git clone https://github.com/JasonRivers/nagios-plugins.git  JR-Nagios-Plugins  && \
    git clone https://github.com/justintime/nagios-plugins.git   JE-Nagios-Plugins  && \
    git clone https://github.com/nagiosenterprises/check_mssql_collection.git   nagios-mssql  && \
    chmod +x /opt/WL-Nagios-Plugins/check*                                          && \
    chmod +x /opt/JE-Nagios-Plugins/check_mem/check_mem.pl                          && \
    cp /opt/JE-Nagios-Plugins/check_mem/check_mem.pl /opt/nagios/libexec/           && \
    cp /opt/nagios-mssql/check_mssql_database.py /opt/nagios/libexec/                         && \
    cp /opt/nagios-mssql/check_mssql_server.py /opt/nagios/libexec/

RUN pip install --no-cache-dir --no-binary=:all: https://github.com/pynag/pynag/tarball/master

RUN cd /tmp \
    && curl -o ndoutils.tar.gz -SL https://github.com/NagiosEnterprises/ndoutils/archive/ndoutils-2.1.3.tar.gz \
    && tar xzf ndoutils.tar.gz \
    && cd /tmp/ndoutils-ndoutils-2.1.3/ \
    && ./configure \
        --prefix="/opt/nagios" \
        --enable-mysql \
        --with-command-group="${NAGIOS_GROUP}" \
        --with-nagios-user="${NAGIOS_USER}" \
        --with-nagios-group="${NAGIOS_GROUP}" \
    && make all \
    && make install \
    && cp /tmp/ndoutils-ndoutils-2.1.3/config/ndo2db.cfg-sample /opt/nagios/etc/ndo2db.cfg \
    && cp /tmp/ndoutils-ndoutils-2.1.3/config/ndomod.cfg-sample /opt/nagios/etc/ndomod.cfg \
    && cp /tmp/ndoutils-ndoutils-2.1.3/db/mysql.sql /opt/nagios/share/mysql-createdb.sql \
    && sed -i 's/ENGINE=MyISAM/ENGINE=MyISAM DEFAULT CHARSET=utf8/g' /opt/nagios/share/mysql-createdb.sql \
    && chmod 666 /opt/nagios/etc/ndomod.cfg

RUN sed -i.bak 's/.*\=www\-data//g' /etc/apache2/envvars
RUN export DOC_ROOT="DocumentRoot $(echo $NAGIOS_HOME/share)"                         && \
    sed -i "s,DocumentRoot.*,$DOC_ROOT," /etc/apache2/sites-enabled/000-default.conf  && \
    sed -i "s,</VirtualHost>,<IfDefine ENABLE_USR_LIB_CGI_BIN>\nScriptAlias /cgi-bin/ /opt/nagios/sbin/\n</IfDefine>\n</VirtualHost>," /etc/apache2/sites-enabled/000-default.conf  && \
    ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load

RUN mkdir -p -m 0755 /usr/share/snmp/mibs                     && \
    mkdir -p         /opt/nagios/etc/conf.d                && \
    mkdir -p         /opt/nagios/etc/monitor               && \
    mkdir -p -m 700  /opt/nagios/.ssh                      && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} /opt/nagios/.ssh  && \
    touch /usr/share/snmp/mibs/.foo                           && \
    ln -s /usr/share/snmp/mibs /opt/nagios/libexec/mibs    && \
    ln -s /opt/nagios/bin/nagios /usr/local/bin/nagios     && \
    download-mibs && echo "mibs +ALL" > /etc/snmp/snmp.conf

RUN sed -i 's,/bin/mail,/usr/bin/mail,' /opt/nagios/etc/objects/commands.cfg  && \
    sed -i 's,/usr/usr,/usr,'           /opt/nagios/etc/objects/commands.cfg

RUN cp /etc/services /var/spool/postfix/etc/  && \
    echo "smtp_address_preference = ipv4" >> /etc/postfix/main.cf

RUN rm -rf /etc/rsyslog.d /etc/rsyslog.conf

RUN rm -rf /etc/sv/getty-5

ADD data /

RUN echo "use_timezone=${NAGIOS_TIMEZONE}" >> /opt/nagios/etc/nagios.cfg

RUN mkdir -p /orig/var && mkdir -p /orig/etc  && \
    cp -Rp /opt/nagios/var/* /orig/var/       && \
    cp -Rp /opt/nagios/etc/* /orig/etc/

RUN a2enmod session         && \
    a2enmod session_cookie  && \
    a2enmod session_crypto  && \
    a2enmod auth_form       && \
    a2enmod request

RUN chmod +x /usr/local/bin/start_nagios        && \
    chmod +x /etc/sv/apache/run                 && \
    chmod +x /etc/sv/nagios/run                 && \
    chmod +x /etc/sv/postfix/run                 && \
    chmod +x /etc/sv/rsyslog/run                 && \
    chmod +x /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

RUN cd /opt/nagiosgraph/etc && \
    sh fix-nagiosgraph-multiple-selection.sh

RUN rm /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

RUN ln -s /etc/sv/* /etc/service

ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

RUN echo "ServerName ${NAGIOS_FQDN}" > /etc/apache2/conf-available/servername.conf    && \
    echo "PassEnv TZ" > /etc/apache2/conf-available/timezone.conf            && \
    ln -s /etc/apache2/conf-available/servername.conf /etc/apache2/conf-enabled/servername.conf    && \
    ln -s /etc/apache2/conf-available/timezone.conf /etc/apache2/conf-enabled/timezone.conf

EXPOSE 80

VOLUME "/opt/nagios/var" "/opt/nagios/etc" "/opt/Custom-Nagios-Plugins" "/opt/nagiosgraph/var" "/opt/nagiosgraph/etc"

CMD [ "/usr/local/bin/start_nagios" ]
