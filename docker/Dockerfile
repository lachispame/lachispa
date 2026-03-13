FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build

ARG FLUTTER_WEB_RENDERER=html

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get

COPY . .

RUN flutter build web --release --web-renderer=$FLUTTER_WEB_RENDERER

FROM nginxinc/nginx-unprivileged:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --spider http://localhost:8080 || exit 1

CMD ["nginx", "-g", "daemon off;"]
