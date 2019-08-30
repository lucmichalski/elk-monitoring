FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY server.template /etc/nginx/conf.d/server.template
COPY status.conf /etc/nginx/conf.d/status.conf
COPY localhost.key /etc/ssl/private/localhost.key
COPY localhost.crt /etc/ssl/certs/localhost.crt
