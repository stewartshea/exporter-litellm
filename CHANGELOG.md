# Changelog

All notable changes to the LiteLLM Prometheus Exporter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-01-09

### Added
- Configurable metrics update interval via `METRICS_UPDATE_INTERVAL` environment variable
- Docker Compose support for easier deployment
- GLWT License
- This CHANGELOG file

### Changed
- Updated documentation with new configuration options
- Reorganized Dockerfile environment variables for better clarity

## [0.1.0] - 2024-01-08

### Added
- Initial release of LiteLLM Prometheus Exporter
- Basic metric collection for LiteLLM usage
- Support for spend, token, request, rate limit, cache, budget, error, entity, API key, and model metrics
- Configurable time windows for different metric types
- Docker support
- Comprehensive documentation
- Database connection pooling
- Health checks
- Prometheus and Grafana integration examples
