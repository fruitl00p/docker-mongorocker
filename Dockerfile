###
#
# A rock mongo container to allow
#
###

FROM    ubuntu:14.04
MAINTAINER Kingsquare <docker@kingsquare.nl>
RUN apt-get update && apt-get dist-upgrade -y
RUN apt-get install -y --no-install-recommends build-essential wget nginx php5-fpm php-pear php5-dev
RUN printf "\n" | pecl install mongo
RUN echo "extension=mongo.so" > /etc/php5/mods-available/mongo.ini && php5enmod mongo

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf

RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

RUN mkdir -p /var/lib/php5/sessions && chown www-data:www-data /var/lib/php5/sessions && chmod 777 /var/lib/php5/sessions
RUN echo "php_value[session.save_path] = /var/lib/php5/sessions" >> /etc/php5/fpm/pool.d/www.conf

# nginx site conf
ADD ./rockmongo /etc/nginx/sites-available/default
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN mkdir /app && \
	cd /app && \
	wget --no-check-certificate https://github.com/iwind/rockmongo/archive/1.1.7.tar.gz && \
	tar -zxvf 1.1.7.tar.gz && \
	mv rockmongo-1.1.7/* . && \
	rm 1.1.7.tar.gz && rmdir rockmongo-1.1.7 && \
	echo "<?php phpinfo(); " > /app/info.php

EXPOSE 80
CMD service php5-fpm start && nginx
