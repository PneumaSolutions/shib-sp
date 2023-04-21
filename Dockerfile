FROM redhat/ubi8:8.7-1112@sha256:e3311058176628ad7f0f288f894ed2afef61be77ad01d53d5b69bca0f6b6cec1

# Define args and set a default value
ARG maintainer=pneumasolutions
ARG imagename=shibboleth-sp
ARG version=3.2.1

MAINTAINER $maintainer
LABEL Vendor="Pneuma Solutions"
LABEL ImageType="Base"
LABEL ImageName=$imagename
LABEL ImageOS=redhat8
LABEL Version=$version

LABEL Build docker build --rm --tag $maintainer/$imagename .

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

RUN rm -fr /var/cache/yum/* && yum clean all && yum -y install --setopt=tsflags=nodocs https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && yum -y update && \
    yum -y install net-tools wget curl tar unzip man vim httpd python38 python38-mod_wsgi supervisor && \
    yum clean all

#install shibboleth, cleanup httpd
COPY system/shib-sp.repo /etc/yum.repos.d/shib-sp.repo
RUN yum -y install shibboleth.x86_64 \
      && yum clean all \
      && rm /etc/httpd/conf.d/autoindex.conf \
      && rm /etc/httpd/conf.d/userdir.conf \
      && rm /etc/httpd/conf.d/welcome.conf

# Shibboleth filesystem setup
RUN rm -f /etc/shibboleth/sp-*.pem \
    && ln -sf /secrets/shib-sp-pki/encryption-key.pem /etc/shibboleth/sp-encrypt-key.pem \
    && ln -sf /secrets/shib-sp-pki/encryption-cert.pem /etc/shibboleth/sp-encrypt-cert.pem \
    && ln -sf /secrets/shib-sp-pki/signing-key.pem /etc/shibboleth/sp-signing-key.pem \
    && ln -sf /secrets/shib-sp-pki/signing-cert.pem /etc/shibboleth/sp-signing-cert.pem \
    && mkdir /etc/shibboleth/adhoc-md
      
ADD ./httpd/shib.conf /etc/httpd/conf.d/
ADD ./shibboleth/* /etc/shibboleth/

# tweaks to httpd configuration
RUN sed -i 's/CustomLog "logs\/access_log"/CustomLog "\/dev\/stdout"/g' /etc/httpd/conf/httpd.conf \
    && sed -i 's/ErrorLog "logs\/error_log"/ErrorLog "\/dev\/stderr"/g' /etc/httpd/conf/httpd.conf \
    && sed -i '/UseCanonicalName/c\UseCanonicalName On' /etc/httpd/conf/httpd.conf
ADD httpd/server-tokens.conf /etc/httpd/conf.d/

# add a basic page to shibb's default protected directory
RUN mkdir -p /var/www/html/sso/
ADD httpd/index.html /var/www/html/sso/


# setup supervisord
ADD system/supervisord.conf /etc/supervisor/
RUN mkdir -p /etc/supervisor/conf.d
ADD system/startup.sh /usr/local/bin/
ADD system/generate_shibboleth_config.py /usr/local/bin/

# Set up the WSGI app
ADD app/requirements.txt /app/
RUN python3.8 -m venv /app/env \
    && . /app/env/bin/activate \
    && python -m pip install -U pip==21.0.1 \
    && pip install -r /app/requirements.txt
ADD app/ /app/
ADD httpd/wsgi.conf /etc/httpd/conf.d/

EXPOSE 80

CMD ["/usr/local/bin/startup.sh"]
