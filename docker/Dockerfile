# Multi-stage build for LaChispa Flutter Web App  
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build

ARG FLUTTER_WEB_RENDERER=html

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --web-renderer=$FLUTTER_WEB_RENDERER

FROM nginx:alpine

RUN addgroup -g 1000 -S userapp && \
    adduser -u 1000 -S userapp -G userapp

RUN chown -R userapp:userapp /usr/share/nginx/html && \
    chown -R userapp:userapp /var/cache/nginx && \
    chown -R userapp:userapp /var/log/nginx && \
    chown -R userapp:userapp /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R userapp:userapp /var/run/nginx.pid

COPY --from=build --chown=userapp:userapp /app/build/web /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

USER userapp

CMD ["nginx", "-g", "daemon off;"]
