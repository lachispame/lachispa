# LaChispa Docker Documentation

English | [Español](#descripcion-general)

---

## Overview

This directory contains all Docker configuration files for deploying LaChispa Web application. LaChispa is a Lightning Network wallet built with Flutter.

## Structure

```text
docker/
├── Dockerfile           # Multi-stage build (Flutter + Nginx)
├── docker-compose.yml   # Service orchestration
├── nginx.conf          # Nginx configuration
└── README.md           # This file
```

## Requirements

- Docker Engine 20.10+
- Docker Compose 2.0+

## Quick Start

### Build and Run

```bash
cd docker
docker-compose up -d --build
```

### Access Application

```text
http://localhost:7777
```

### View Logs

```bash
docker-compose logs -f
```

### Stop Services

```bash
docker-compose down
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NGINX_HOST` | `localhost` | Nginx host |
| `NGINX_PORT` | `80` | Nginx port |

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `FLUTTER_WEB_RENDERER` | `html` | Flutter web renderer (`html` or `canvaskit`) |

### Ports

| Port | Service |
|------|---------|
| `7777` | HTTP (Nginx) |

## Production Deployment

### With Traefik

The service includes Traefik labels for automatic discovery:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.lachispa.rule=Host(`lachispa.local`)"
  - "traefik.http.services.lachispa.loadbalancer.server.port=80"
```

Ensure Traefik is running in your Docker environment.

### Standalone

```bash
docker-compose up -d --build
```

## Health Check

The container includes a health check that verifies the web server responds:

```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

## Resource Limits

Default deployment includes resource limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M
```

## Nginx Features

### Enabled Features

- Gzip compression
- Rate limiting (10 req/s API, 30 req/s general)
- Security headers (CSP, X-Frame-Options, etc.)
- Static asset caching (1 year)
- PWA support (service worker caching)

### Security Headers

```text
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; ...
```

### Rate Limiting

- API endpoints: 10 requests/second
- General requests: 30 requests/second
- Burst: 20 requests

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs

# Verify ports aren't in use
netstat -tulpn | grep 7777
```

### Build Fails

```bash
# Clean build cache
docker-compose build --no-cache
```

### Check Health Status

```bash
docker inspect lachispa-web | grep -A 20 "Health"
```

## Development

### Rebuild on Changes

```bash
docker-compose up -d --build
```

### Access Container Shell

```bash
docker exec -it lachispa-web sh
```

## License

See root project LICENSE file.

---

# Documentación de Docker - LaChispa

[English](#overview) | Español

---

## Descripción General

Este directorio contiene todos los archivos de configuración Docker para desplegar la aplicación web de LaChispa. LaChispa es una billetera de Lightning Network construida con Flutter.

## Estructura

```text
docker/
├── Dockerfile           # Build multi-stage (Flutter + Nginx)
├── docker-compose.yml   # Orquestación de servicios
├── nginx.conf          # Configuración de Nginx
└── README.md           # Este archivo
```

## Requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+

## Inicio Rápido

### Construir y Ejecutar

```bash
cd docker
docker-compose up -d --build
```

### Acceder a la Aplicación

```text
http://localhost:7777
```

### Ver Logs

```bash
docker-compose logs -f
```

### Detener Servicios

```bash
docker-compose down
```

## Configuración

### Variables de Entorno

| Variable | Valor Predeterminado | Descripción |
|----------|---------------------|-------------|
| `NGINX_HOST` | `localhost` | Host de Nginx |
| `NGINX_PORT` | `80` | Puerto de Nginx |

### Argumentos de Build

| Argumento | Valor Predeterminado | Descripción |
|-----------|---------------------|-------------|
| `FLUTTER_WEB_RENDERER` | `html` | Renderizador web de Flutter (`html` o `canvaskit`) |

### Puertos

| Puerto | Servicio |
|--------|----------|
| `7777` | HTTP (Nginx) |

## Despliegue en Producción

### Con Traefik

El servicio incluye etiquetas de Traefik para descubrimiento automático:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.lachispa.rule=Host(`lachispa.local`)"
  - "traefik.http.services.lachispa.loadbalancer.server.port=80"
```

Asegúrate de que Traefik esté ejecutándose en tu entorno Docker.

### Autónomo

```bash
docker-compose up -d --build
```

## Verificación de Salud

El contenedor incluye una verificación de salud que verifica que el servidor web responde:

```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

## Límites de Recursos

El despliegue incluye límites de recursos por defecto:

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 512M
```

## Características de Nginx

### Características Habilitadas

- Compresión Gzip
- Limitación de tasa (10 req/s API, 30 req/s general)
- Encabezados de seguridad (CSP, X-Frame-Options, etc.)
- Caché de activos estáticos (1 año)
- Soporte PWA (caché service worker)

### Encabezados de Seguridad

```text
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; ...
```

### Limitación de Tasa

- Endpoints API: 10 solicitudes/segundo
- Solicitudes generales: 30 solicitudes/segundo
- Ráfaga: 20 solicitudes

## Solución de Problemas

### El Contenedor No Inicia

```bash
# Verificar logs
docker-compose logs

# Verificar puertos en uso
netstat -tulpn | grep 7777
```

### El Build Falla

```bash
# Limpiar caché de build
docker-compose build --no-cache
```

### Verificar Estado de Salud

```bash
docker inspect lachispa-web | grep -A 20 "Health"
```

## Desarrollo

### Recompilar Cambios

```bash
docker-compose up -d --build
```

### Acceder al Shell del Contenedor

```bash
docker exec -it lachispa-web sh
```

## Licencia

Ver archivo LICENSE en la raíz del proyecto.
