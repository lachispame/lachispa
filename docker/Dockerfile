# Multi-stage build for LaChispa Flutter Web App  
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build

ARG FLUTTER_WEB_RENDERER=html

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --web-renderer=$FLUTTER_WEB_RENDERER

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]