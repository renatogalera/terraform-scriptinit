FROM php:7.3-apache
RUN apt-get update
RUN mkdir /etc/apache2/ssl
COPY ssl/server.crt /etc/apache2/conf/ssl/server.crt
COPY ssl/server.key /etc/apache2/conf/ssl/server.key
ADD index.html /var/www/html/
ADD index.html /var/www/
COPY ssl/vhost.conf /etc/apache2/sites-enabled/vhost.conf
RUN a2enmod rewrite
RUN a2enmod ssl
RUN service apache2 restart
EXPOSE 80
EXPOSE 443
