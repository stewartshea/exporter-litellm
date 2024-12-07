# Environment Variables Reference

This document lists all environment variables supported by the LiteLLM Prometheus Exporter.

## Database Connection

### LITELLM_DB_HOST
- **Description**: PostgreSQL database host address
- **Default**: `localhost`
- **Example**: `LITELLM_DB_HOST=db.example.com`

### LITELLM_DB_PORT
- **Description**: PostgreSQL database port
- **Default**: `5432`
- **Example**: `LITELLM_DB_PORT=5432`

### LITELLM_DB_NAME
- **Description**: PostgreSQL database name
- **Default**: `litellm`
- **Example**: `LITELLM_DB_NAME=litellm_prod`

### LITELLM_DB_USER
- **Description**: PostgreSQL database user
- **Default**: `postgres`
- **Example**: `LITELLM_DB_USER=litellm_readonly`
- **Note**: For security, use a read-only user. See [POSTGRES_SETUP.md](POSTGRES_SETUP.md)

### LITELLM_DB_PASSWORD
- **Description**: PostgreSQL database password
- **Default**: ` ` (empty string)
- **Example**: `LITELLM_DB_PASSWORD=your_secure_password`
- **Note**: Use a strong password in production

## Database Connection Pool

### DB_MIN_CONNECTIONS
- **Description**: Minimum number of database connections to maintain in the pool
- **Default**: `1`
- **Example**: `DB_MIN_CONNECTIONS=2`
- **Impact**: Lower values use less resources but may increase connection setup time

### DB_MAX_CONNECTIONS
- **Description**: Maximum number of database connections allowed in the pool
- **Default**: `10`
- **Example**: `DB_MAX_CONNECTIONS=20`
- **Impact**: Higher values handle more concurrent requests but use more resources

## Metrics Configuration

### METRICS_PORT
- **Description**: Port where the Prometheus metrics will be exposed
- **Default**: `9090`
- **Example**: `METRICS_PORT=9091`
- **Note**: Ensure this port is accessible to your Prometheus server

### METRICS_UPDATE_INTERVAL
- **Description**: How frequently metrics are updated, in seconds
- **Default**: `15`
- **Example**: `METRICS_UPDATE_INTERVAL=30`
- **Impact**: 
  - Lower values (e.g., 5) provide more real-time data but increase database load
  - Higher values (e.g., 60) reduce database load but decrease metric freshness

## Time Windows

### METRICS_SPEND_WINDOW
- **Description**: Time window for spend metrics
- **Default**: `30d`
- **Example**: `METRICS_SPEND_WINDOW=7d`
- **Valid Units**: 'd' (days), 'h' (hours), 'm' (minutes)
- **Impact**: Affects historical spend analysis and memory usage

### METRICS_REQUEST_WINDOW
- **Description**: Time window for request metrics
- **Default**: `24h`
- **Example**: `METRICS_REQUEST_WINDOW=12h`
- **Valid Units**: 'd' (days), 'h' (hours), 'm' (minutes)
- **Impact**: Affects request rate calculations and throughput metrics

### METRICS_ERROR_WINDOW
- **Description**: Time window for error metrics
- **Default**: `1h`
- **Example**: `METRICS_ERROR_WINDOW=30m`
- **Valid Units**: 'd' (days), 'h' (hours), 'm' (minutes)
- **Impact**: Affects error rate calculations and alert sensitivity

## Example Usage

### Docker Run
```bash
docker run -d \
  -p 9090:9090 \
  -e LITELLM_DB_HOST=your-db-host \
  -e LITELLM_DB_PORT=5432 \
  -e LITELLM_DB_NAME=litellm \
  -e LITELLM_DB_USER=litellm_readonly \
  -e LITELLM_DB_PASSWORD=your_secure_password \
  -e DB_MIN_CONNECTIONS=2 \
  -e DB_MAX_CONNECTIONS=10 \
  -e METRICS_UPDATE_INTERVAL=15 \
  -e METRICS_SPEND_WINDOW=30d \
  -e METRICS_REQUEST_WINDOW=24h \
  -e METRICS_ERROR_WINDOW=1h \
  litellm-exporter
```

### Docker Compose
```yaml
services:
  litellm-exporter:
    environment:
      - LITELLM_DB_HOST=your-db-host
      - LITELLM_DB_PORT=5432
      - LITELLM_DB_NAME=litellm
      - LITELLM_DB_USER=litellm_readonly
      - LITELLM_DB_PASSWORD=your_secure_password
      - DB_MIN_CONNECTIONS=2
      - DB_MAX_CONNECTIONS=10
      - METRICS_UPDATE_INTERVAL=15
      - METRICS_SPEND_WINDOW=30d
      - METRICS_REQUEST_WINDOW=24h
      - METRICS_ERROR_WINDOW=1h
```

### Local Development
```bash
export LITELLM_DB_HOST=localhost
export LITELLM_DB_PORT=5432
export LITELLM_DB_NAME=litellm
export LITELLM_DB_USER=litellm_readonly
export LITELLM_DB_PASSWORD=your_secure_password
export DB_MIN_CONNECTIONS=1
export DB_MAX_CONNECTIONS=5
export METRICS_UPDATE_INTERVAL=15
export METRICS_SPEND_WINDOW=30d
export METRICS_REQUEST_WINDOW=24h
export METRICS_ERROR_WINDOW=1h
```

## Best Practices

1. **Security**:
   - Use a read-only database user
   - Set strong passwords
   - Consider using environment-specific values

2. **Performance**:
   - Adjust time windows based on your data volume
   - Set appropriate connection pool sizes
   - Monitor database load and adjust update interval

3. **Monitoring**:
   - Start with default values
   - Monitor system performance
   - Adjust based on your specific needs
