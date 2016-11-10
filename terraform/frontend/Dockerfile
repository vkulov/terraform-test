FROM nginx:alpine

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY conf/mime.types /etc/nginx/conf/mime.types

COPY conf/php /etc/nginx/php

COPY conf/fastcgi_params /etc/nginx/fastcgi_params

COPY src /var/www/html

RUN mkdir -p /run/nginx

EXPOSE 3000