#!/bin/bash

export FULL_GMAIL_ADDR=$GMAIL_ACCOUNT@gmail.com

# Verify if /.ssmtp_configured exists !
if [ -f /.ssmtp_configured ];
then
  echo "••• `date` - Skipped sSMTP configuration. SMTP is ready !"
else
  echo "••• `date` - Configuring SMTP to send e-mail using GMail Account"
  # Create backup of conf file
  ssmtp_file=/etc/ssmtp/ssmtp.conf
  backupfile_time=`date +%H%M%S`
  cp $ssmtp_file $ssmtp_file.$backupfile_time
  # Merging my .GMAILRC into ssmtp.conf file
  echo "#" >> /etc/ssmtp/ssmtp.conf
  echo "Debug=YES" >> /etc/ssmtp/ssmtp.conf
  echo "#" >> /etc/ssmtp/ssmtp.conf
  if [[ -f "/root/ssmtp/conf/.GMAILRC" ]] ; then
    # If we have a custom .GMAILRC, append it to ssmtp.conf
    cat /root/ssmtp/conf/.GMAILRC >> /etc/ssmtp/ssmtp.conf
  fi
  echo "••• `date` - GMAIL_ACCOUNT=$GMAIL_ACCOUNT"
  echo "••• `date` - FULL_GMAIL_ADDR=$FULL_GMAIL_ADDR"
  # Example of sed inplace command:
  # sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
  sed -Ei "s/^root=.*/root=$FULL_GMAIL_ADDR/"  /etc/ssmtp/ssmtp.conf
  sed -Ei "s/^mailhub=.*/mailhub=smtp.gmail.com:465/"  /etc/ssmtp/ssmtp.conf
  echo "rewriteDomain=gmail.com" >> /etc/ssmtp/ssmtp.conf
  echo "••• `date` - /etc/ssmtp/ssmtp.conf final content"
  cat /etc/ssmtp/ssmtp.conf
  echo "••••••••••••••••••••••••••••••••••••••••••"
  # Using se to replace -container-name- and -now-
  CONTAINER_ID=`uname -n`
  DATE_NOW=`date`
  echo "••• `date` - replacing -gmail_account-"
  sed -Ei "s/gmail_account/$GMAIL_ACCOUNT/g" /root/ssmtp/conf/container-started-message.txt
  echo "••• `date` - replacing -container-name-"
  sed -Ei "s/container_name/$CONTAINER_ID/g" /root/ssmtp/conf/container-started-message.txt
  echo "••• `date` - replacing -now-"
  sed -Ei "s/date_now/$DATE_NOW/g" /root/ssmtp/conf/container-started-message.txt
  echo "••• `date` - Updating PHP.INI to use sSMTP"
  PHPINI='/etc/php5/apache2/php.ini'
  SENDMAIL_PATH=';sendmail_path ='
  SSMTPMAIL_PATH='sendmail_path = \/usr\/sbin\/ssmtp -t'
  sed -i "/;sendmail_path =/c\\$SSMTPMAIL_PATH" $PHPINI
  cat $PHPINI | egrep -v "^;" | egrep "mail|smtp|SMTP"
  if [[ -f "/root/php/conf/php.ini" ]] ; then
    # If we have a custom conf, use that instead
    cp /root/php/conf/php.ini $PHPINI
  fi
  touch /.ssmtp_configured
fi

echo "••• `date` - Sending email notification to $FULL_GMAIL_ADDR"
# I will always send a message when container starts
cp /root/ssmtp/conf/container-started-message.txt \
   /tmp/container-started-msg.txt
echo "" >> /tmp/container-started-msg.txt
echo "••• `date` - /app/custom directory content" >> /tmp/container-started-msg.txt
echo "" >> /tmp/container-started-msg.txt
ls -lat /app/custom >> /tmp/container-started-msg.txt
/usr/sbin/ssmtp $FULL_GMAIL_ADDR < /tmp/container-started-msg.txt

# Verify if file /.mysql_db_created exists !
if [ -f /.mysql_db_created ];
then
  exec supervisord -n
  exit 1
fi

# Waiting 5 seconds
sleep 5
echo "••• `date` - Verifying if DB wordpress EXISTS. Using Environment Variables:"
echo "••• `date` - MYSQL_PORT_3306_TCP_ADDR=$MYSQL_PORT_3306_TCP_ADDR"
echo "••• `date` - MYSQL_PORT_3306_TCP_PORT=$MYSQL_PORT_3306_TCP_PORT"
echo "••• `date` - MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"
echo "••• `date` - Using MySQL User root to connect "

DEBUB_MSG=$(mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_PORT_3306_TCP_ADDR -P$MYSQL_PORT_3306_TCP_PORT -e "SHOW DATABASES LIKE 'wordpress';")
echo "••• `date` - DEBUB_MSG='$DEBUB_MSG'"

DB_EXISTS=$(mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_PORT_3306_TCP_ADDR -P$MYSQL_PORT_3306_TCP_PORT -e "SHOW DATABASES LIKE 'wordpress';" | grep "wordpress" > /dev/null; echo "$?")
echo "••• `date` - Result: DB_EXISTS=$DB_EXISTS"

WP_VERSION="4.4"

if [[ DB_EXISTS -eq 1 ]];
then
  echo "••• `date` - Creating database wordpress for Wordpress $WP_VERSION"
  RET=1
  while [[ RET -ne 0 ]]; do
    sleep 5
    echo "••• `date` - Trying create database SQL command"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_PORT_3306_TCP_ADDR \
          -P$MYSQL_PORT_3306_TCP_PORT -e "CREATE DATABASE wordpress"
    RET=$?
  done
  echo "••• `date` - Database wordpress for Wordpress $WP_VERSION was created!"
  ### echo "••• `date` - Appending defition for WP_CONTENT_DIR for Wordpress"
  ### # sed -Ei "s/define\('WP_DEBUG', false\);/define\('WP_DEBUG', true\);\n\ndefine\( 'WP_CONTENT_DIR', dirname\(__FILE__\) . 'custom' \);\n/" wp-config-sample.php
  ### # Removendo as linhas do final do arquivo
  ### sed -i '82,89d' wp-config-sample.php
  ### sed -Ei "s/WP_DEBUG', false\);/WP_DEBUG', false\);\n/" wp-config-sample.php
  ### cat /root/wp/conf/wp-config-fragment.php >> wp-config-sample.php
  ### # See: https://codex.wordpress.org/Editing_wp-config.php#Moving_wp-content_folder
  tail -n 20 wp-config-sample.php
else
  echo "••• `date` - Skipped creation of database wordpress for Wordpress $WP_VERSION – it already exists."
fi

mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_PORT_3306_TCP_ADDR \
          -P$MYSQL_PORT_3306_TCP_PORT \
          -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wp'@'%' WITH GRANT OPTION"

touch /.mysql_db_created

echo "••• `date` - /var/www/html directory"
ls -la /var/www/html

echo "••• `date` - /etc/supervisor/conf.d/supervisord-apache2.conf file content"
cat /etc/supervisor/conf.d/supervisord-apache2.conf
echo "••• `date` - /start.sh file content"
cat /start.sh
echo "••• `date` - /etc/apache2/envvars file content"
cat /etc/apache2/envvars | egrep -v "^#"
echo "••• `date` - /var/log/apache2 directory"
ls -lat /var/log/apache2
echo "••• `date` - /etc/ssmtp/ssmtp.conf file content"
cat /etc/ssmtp/ssmtp.conf
echo "••• `date` - /app/custom directory content"
mkdir -p /app/custom/plugins
mkdir -p /app/custom/themes
ls -lat /app/custom
MY_DIR=`pwd`
cd /app/wp-content/plugins
unzip /wp-resources/plugins/dynamic-to-top.3.4.2.zip && \
      unzip /wp-resources/plugins/mobble.zip && \
      unzip /wp-resources/plugins/page-scroll-to-id.1.6.0.zip && \
      unzip /wp-resources/plugins/portfolio-post-type.0.9.2.zip
cd ../themes
unzip /wp-resources/themes/one-pager-genesis.zip
unzip /wp-resources/themes/genesis.zip
rm -rf __MACOSX/
cd $MY_DIR
echo "••• `date` - pwd : `pwd`"
cd wp-content
echo "••• `date` - pwd : `pwd`"
chown -R www-data:www-data *
ls -lat languages
ls -lat plugins
ls -lat themes
ls -lat upgrade
echo "•••"
echo "••• `date` - supervisord take the control"
echo "•••"
exec supervisord -n
