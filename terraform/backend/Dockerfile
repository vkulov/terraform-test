FROM php:5.6.26-fpm-alpine

COPY src /var/www/html

RUN	cd /usr/local/etc \
    && { \
		echo '[www]'; \
		echo 'php_admin_flag[log_errors] = on'; \
	} | tee php-fpm.d/docker1.conf \
