FROM nginx:alpine

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY conf/mime.types /etc/nginx/conf/mime.types

COPY src /var/www/html

RUN mkdir -p /run/nginx

EXPOSE 3000