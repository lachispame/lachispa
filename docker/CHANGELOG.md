# Docker Changelog

All notable changes to Docker configuration are documented in this file.

## [1.0.0] - 2026-03-01

### Added
- Multi-stage Docker build with Flutter 3.27.3
- Health check configuration
- Resource limits (CPU and memory)
- Rate limiting in Nginx (10 req/s API, 30 req/s general)
- Content-Security-Policy header
- Build arguments for web renderer customization
- Complete bilingual documentation (English/Spanish)

### Changed
- Directory structure: moved all Docker files to `docker/` subdirectory
- Docker Compose context updated to support new directory structure
- Nginx configuration enhanced with rate limiting and CSP

### Security
- Added Content-Security-Policy header
- Added rate limiting to prevent DDoS
- Configured secure HTTP headers (X-Frame-Options, X-Content-Type-Options, etc.)

### Documentation
- Bilingual README (English primary, Spanish for Hispanic speakers)
- Quick start guide
- Troubleshooting section
- Configuration reference tables
