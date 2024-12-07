FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY litellm_exporter.py .

# Default environment variables
ENV METRICS_PORT=9090
ENV LITELLM_DB_HOST=localhost
ENV LITELLM_DB_PORT=5432
ENV LITELLM_DB_NAME=litellm
ENV LITELLM_DB_USER=postgres
ENV LITELLM_DB_PASSWORD=
ENV DB_MIN_CONNECTIONS=1
ENV DB_MAX_CONNECTIONS=10

# Metric collection configuration
ENV METRICS_UPDATE_INTERVAL=15
ENV METRICS_SPEND_WINDOW=30d
ENV METRICS_REQUEST_WINDOW=24h
ENV METRICS_ERROR_WINDOW=1h

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${METRICS_PORT} || exit 1

# Create non-root user
RUN useradd -m -u 1000 exporter
USER exporter

EXPOSE ${METRICS_PORT}

# Use tini as init system to handle signals properly
ENV TINI_VERSION v0.19.0
ADD --chmod=755 https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ENTRYPOINT ["/tini", "--"]

# Run the exporter
CMD ["python", "litellm_exporter.py"]
