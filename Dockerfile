FROM parana/wily-php

MAINTAINER João Antonio Ferreira "joao.parana@gmail.com"

ENV REFRESHED_AT 2016-03-26

# Install packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor pwgen && \
    apt-get -y install mysql-client --fix-missing && \
    apt-get -y install build-essential ssmtp --fix-missing

WORKDIR /tmp

ENV WP_VERSION  4.4.2

# Download Wordpress into /app
RUN rm -rf /app && mkdir /app && \
    curl -L -O https://wordpress.org/wordpress-$WP_VERSION.tar.gz && \
    tar -xzvf wordpress-$WP_VERSION.tar.gz -C /app --strip-components=1 && \
    rm wordpress-$WP_VERSION.tar.gz

RUN apt-get update && \
    apt-get -y install unzip mailutils mutt nano

RUN mkdir -p /root/ssmtp/conf && \
    mkdir -p /root/php/conf && \
    mkdir -p /root/wp/conf

COPY conf/smtp/* /root/ssmtp/conf/
COPY conf/php/php.ini /root/php/conf/php.ini
COPY conf/wp/wp-config-fragment.php /root/wp/conf/wp-config-fragment.php

RUN echo "••• Configuração original do SMTP •••" && \
    cat /etc/ssmtp/ssmtp.conf && \
    echo "•••••••••••••••••••••••••••••••••••••"

# If you prefer you can add wp-config with info for Wordpress to connect to DB
# ADD wp-config.php /app/wp-config.php
# RUN chmod 644 /app/wp-config.php

# Or leave it alone and run a shell script to customize
RUN ls -lat /app && cat /app/wp-config-sample.php

# Fix permissions for apache
RUN chown -R www-data:www-data /app
# Add home for custom plugins and themes provided by VOLUME
RUN mkdir -p /app/custom
RUN chown -R www-data:www-data /app/custom

# Add script to create 'wordpress' DB
ADD run-wp.sh /run-wp.sh
RUN chmod 755 /*.sh

WORKDIR /app

# To control the user and group for VOLUME shared folder
RUN groupadd code_executor -g 1000 && \
    useradd code_executor -g code_executor -u 1000

# Plugins and themes customization
VOLUME ["/app/custom"]
RUN ls -lat /app/custom

ENV PHPINI_FULL_FILENAME='/etc/php5/apache2/php.ini'
RUN cat $PHPINI_FULL_FILENAME | egrep -v "^;" | egrep "mail|smtp|SMTP"

EXPOSE 80

ADD resources /wp-resources

CMD ["/run-wp.sh"]
