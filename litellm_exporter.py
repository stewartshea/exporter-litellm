import os
import time
from datetime import datetime, timedelta
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2 import pool
from prometheus_client import start_http_server, Gauge, Counter, Histogram, Info
import logging
from typing import Optional, Dict, Any
import backoff

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MetricsConfig:
    def __init__(self):
        # Time windows for different types of metrics
        self.spend_window = os.getenv('METRICS_SPEND_WINDOW', '30d')  # Default 30 days for spend metrics
        self.request_window = os.getenv('METRICS_REQUEST_WINDOW', '24h')  # Default 24 hours for request metrics
        self.error_window = os.getenv('METRICS_ERROR_WINDOW', '1h')  # Default 1 hour for error metrics
        self.update_interval = int(os.getenv('METRICS_UPDATE_INTERVAL', '15'))  # Default 15 seconds for metrics update
        
        # Convert time window strings to PostgreSQL intervals
        self.time_windows = {
            'spend': self._parse_time_window(self.spend_window),
            'request': self._parse_time_window(self.request_window),
            'error': self._parse_time_window(self.error_window)
        }

    def _parse_time_window(self, window: str) -> str:
        """Convert time window string (e.g., '30d', '24h') to PostgreSQL interval."""
        unit = window[-1].lower()
        value = int(window[:-1])
        
        units = {
            'd': 'days',
            'h': 'hours',
            'm': 'minutes'
        }
        
        if unit not in units:
            raise ValueError(f"Invalid time window unit: {unit}. Use 'd' for days, 'h' for hours, or 'm' for minutes.")
        
        return f"{value} {units[unit]}"

class DatabaseConfig:
    def __init__(self):
        self.host = os.getenv('LITELLM_DB_HOST', 'localhost')
        self.port = os.getenv('LITELLM_DB_PORT', '5432')
        self.name = os.getenv('LITELLM_DB_NAME', 'litellm')
        self.user = os.getenv('LITELLM_DB_USER', 'postgres')
        self.password = os.getenv('LITELLM_DB_PASSWORD', '')
        self.min_connections = int(os.getenv('DB_MIN_CONNECTIONS', '1'))
        self.max_connections = int(os.getenv('DB_MAX_CONNECTIONS', '10'))

class DatabaseConnection:
    def __init__(self, config: DatabaseConfig):
        self.config = config
        self.connection_pool = None
        self.setup_connection_pool()

    def setup_connection_pool(self):
        try:
            self.connection_pool = psycopg2.pool.SimpleConnectionPool(
                self.config.min_connections,
                self.config.max_connections,
                host=self.config.host,
                port=self.config.port,
                database=self.config.name,
                user=self.config.user,
                password=self.config.password
            )
            logger.info("Database connection pool created successfully")
        except Exception as e:
            logger.error(f"Error creating connection pool: {e}")
            raise

    @backoff.on_exception(backoff.expo, Exception, max_tries=5)
    def execute_query(self, query: str, params: Optional[Dict[str, Any]] = None) -> list:
        conn = None
        cur = None
        try:
            conn = self.connection_pool.getconn()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute(query, params or {})
            return cur.fetchall()
        except Exception as e:
            logger.error(f"Database query error: {e}")
            raise
        finally:
            if cur:
                cur.close()
            if conn:
                self.connection_pool.putconn(conn)

class MetricQueries:
    @staticmethod
    def get_spend_metrics(time_window: str) -> str:
        return """
        WITH spend_data AS (
            SELECT 
                s.model,
                SUM(s.spend) as total_spend,
                SUM(s.total_tokens) as total_tokens,
                SUM(s.prompt_tokens) as prompt_tokens,
                SUM(s.completion_tokens) as completion_tokens,
                COUNT(*) as request_count,
                COUNT(CASE WHEN s.cache_hit = 'true' THEN 1 END) as cache_hits,
                COUNT(CASE WHEN s.cache_hit = 'false' THEN 1 END) as cache_misses,
                u.user_id,
                u.user_alias,
                t.team_id,
                t.team_alias,
                o.organization_id,
                o.organization_alias
            FROM "LiteLLM_SpendLogs" s
            LEFT JOIN "LiteLLM_UserTable" u ON s."user" = u.user_id
            LEFT JOIN "LiteLLM_TeamTable" t ON s.team_id = t.team_id
            LEFT JOIN "LiteLLM_OrganizationTable" o ON t.organization_id = o.organization_id
            WHERE s."startTime" >= NOW() - INTERVAL %(time_window)s
            GROUP BY s.model, u.user_id, u.user_alias, t.team_id, t.team_alias, 
                     o.organization_id, o.organization_alias
        )
        SELECT * FROM spend_data
        """

    @staticmethod
    def get_rate_limits() -> str:
        return """
        SELECT 
            'user' as entity_type,
            user_id as entity_id,
            user_alias as entity_alias,
            tpm_limit,
            rpm_limit,
            max_parallel_requests,
            blocked
        FROM "LiteLLM_UserTable"
        WHERE tpm_limit IS NOT NULL 
           OR rpm_limit IS NOT NULL 
           OR max_parallel_requests IS NOT NULL
           OR blocked = true
        UNION ALL
        SELECT 
            'team' as entity_type,
            team_id as entity_id,
            team_alias as entity_alias,
            tpm_limit,
            rpm_limit,
            max_parallel_requests,
            blocked
        FROM "LiteLLM_TeamTable"
        WHERE tpm_limit IS NOT NULL 
           OR rpm_limit IS NOT NULL 
           OR max_parallel_requests IS NOT NULL
           OR blocked = true
        """

    @staticmethod
    def get_budget_metrics() -> str:
        return """
        WITH budget_data AS (
            SELECT 
                b.budget_id,
                b.max_budget,
                b.soft_budget,
                b.budget_reset_at,
                COALESCE(u.user_id, t.team_id, o.organization_id) as entity_id,
                CASE 
                    WHEN u.user_id IS NOT NULL THEN 'user'
                    WHEN t.team_id IS NOT NULL THEN 'team'
                    WHEN o.organization_id IS NOT NULL THEN 'organization'
                END as entity_type,
                COALESCE(u.user_alias, t.team_alias, o.organization_alias) as entity_alias,
                COALESCE(u.spend, t.spend, o.spend) as current_spend
            FROM "LiteLLM_BudgetTable" b
            LEFT JOIN "LiteLLM_UserTable" u ON u.budget_id = b.budget_id
            LEFT JOIN "LiteLLM_TeamTable" t ON t.team_id = b.budget_id
            LEFT JOIN "LiteLLM_OrganizationTable" o ON o.budget_id = b.budget_id
        )
        SELECT * FROM budget_data
        """

    @staticmethod
    def get_key_metrics() -> str:
        return """
        SELECT 
            token,
            key_name,
            key_alias,
            expires,
            user_id,
            team_id,
            blocked,
            spend
        FROM "LiteLLM_VerificationToken"
        """

class LiteLLMMetrics:
    def __init__(self):
        # Spend metrics
        self.total_spend = Gauge('litellm_total_spend', 'Total spend across all users', ['model'])
        self.user_spend = Gauge('litellm_user_spend', 'Spend by user', ['user_id', 'user_alias', 'model'])
        self.team_spend = Gauge('litellm_team_spend', 'Spend by team', ['team_id', 'team_alias', 'model'])
        self.org_spend = Gauge('litellm_org_spend', 'Spend by organization', ['organization_id', 'organization_alias', 'model'])

        # Token metrics
        self.total_tokens = Gauge('litellm_total_tokens', 'Total tokens used', ['model'])
        self.prompt_tokens = Gauge('litellm_prompt_tokens', 'Prompt tokens used', ['model'])
        self.completion_tokens = Gauge('litellm_completion_tokens', 'Completion tokens used', ['model'])

        # Request metrics
        self.requests_total = Gauge('litellm_requests_total', 'Total number of requests', ['model'])
        self.cache_hits = Gauge('litellm_cache_hits_total', 'Total number of cache hits', ['model'])
        self.cache_misses = Gauge('litellm_cache_misses_total', 'Total number of cache misses', ['model'])

        # Rate limit metrics
        self.tpm_limit = Gauge('litellm_tpm_limit', 'Tokens per minute limit', ['entity_type', 'entity_id', 'entity_alias'])
        self.rpm_limit = Gauge('litellm_rpm_limit', 'Requests per minute limit', ['entity_type', 'entity_id', 'entity_alias'])
        self.parallel_requests = Gauge('litellm_parallel_requests', 'Maximum parallel requests', ['entity_type', 'entity_id', 'entity_alias'])

        # Budget metrics
        self.budget_utilization = Gauge('litellm_budget_utilization', 'Budget utilization percentage', ['entity_type', 'entity_id', 'entity_alias'])
        self.max_budget = Gauge('litellm_max_budget', 'Maximum budget', ['entity_type', 'entity_id', 'entity_alias'])
        self.soft_budget = Gauge('litellm_soft_budget', 'Soft budget limit', ['entity_type', 'entity_id', 'entity_alias'])
        self.budget_reset = Gauge('litellm_budget_reset_time', 'Time until budget reset in seconds', ['entity_type', 'entity_id', 'entity_alias'])

        # Status metrics
        self.blocked_status = Gauge('litellm_blocked_status', 'Entity blocked status', ['entity_type', 'entity_id', 'entity_alias'])
        
        # Key metrics
        self.key_expiry = Gauge('litellm_key_expiry', 'Time until key expiry in seconds', ['key_name', 'key_alias'])
        self.key_spend = Gauge('litellm_key_spend', 'Current spend for key', ['key_name', 'key_alias'])

class MetricsCollector:
    def __init__(self, db_connection: DatabaseConnection, metrics: LiteLLMMetrics, config: MetricsConfig):
        self.db = db_connection
        self.metrics = metrics
        self.config = config

    def update_spend_metrics(self):
        results = self.db.execute_query(
            MetricQueries.get_spend_metrics(),
            {'time_window': self.config.time_windows['spend']}
        )
        
        for row in results:
            model = row['model'] or 'unknown'
            
            # Update model-level metrics
            self.metrics.total_spend.labels(model=model).set(row['total_spend'] or 0)
            self.metrics.total_tokens.labels(model=model).set(row['total_tokens'] or 0)
            self.metrics.prompt_tokens.labels(model=model).set(row['prompt_tokens'] or 0)
            self.metrics.completion_tokens.labels(model=model).set(row['completion_tokens'] or 0)
            self.metrics.requests_total.labels(model=model).set(row['request_count'])
            self.metrics.cache_hits.labels(model=model).set(row['cache_hits'] or 0)
            self.metrics.cache_misses.labels(model=model).set(row['cache_misses'] or 0)
            
            # Update user/team/org specific metrics
            if row['user_id']:
                self.metrics.user_spend.labels(
                    user_id=row['user_id'],
                    user_alias=row['user_alias'] or 'none',
                    model=model
                ).set(row['total_spend'] or 0)
            
            if row['team_id']:
                self.metrics.team_spend.labels(
                    team_id=row['team_id'],
                    team_alias=row['team_alias'] or 'none',
                    model=model
                ).set(row['total_spend'] or 0)
            
            if row['organization_id']:
                self.metrics.org_spend.labels(
                    organization_id=row['organization_id'],
                    organization_alias=row['organization_alias'] or 'none',
                    model=model
                ).set(row['total_spend'] or 0)

    def update_rate_limits(self):
        results = self.db.execute_query(MetricQueries.get_rate_limits())
        
        for row in results:
            entity_type = row['entity_type']
            entity_id = row['entity_id']
            entity_alias = row['entity_alias'] or 'none'
            
            if row['tpm_limit']:
                self.metrics.tpm_limit.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(row['tpm_limit'])
            
            if row['rpm_limit']:
                self.metrics.rpm_limit.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(row['rpm_limit'])
            
            if row['max_parallel_requests']:
                self.metrics.parallel_requests.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(row['max_parallel_requests'])
            
            if row['blocked']:
                self.metrics.blocked_status.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(1)

    def update_budget_metrics(self):
        results = self.db.execute_query(MetricQueries.get_budget_metrics())
        
        for row in results:
            entity_type = row['entity_type']
            entity_id = row['entity_id']
            entity_alias = row['entity_alias'] or 'none'
            
            if row['max_budget']:
                self.metrics.max_budget.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(row['max_budget'])
                
                if row['current_spend']:
                    utilization = (row['current_spend'] / row['max_budget']) * 100
                    self.metrics.budget_utilization.labels(
                        entity_type=entity_type,
                        entity_id=entity_id,
                        entity_alias=entity_alias
                    ).set(utilization)
            
            if row['soft_budget']:
                self.metrics.soft_budget.labels(
                    entity_type=entity_type,
                    entity_id=entity_id,
                    entity_alias=entity_alias
                ).set(row['soft_budget'])
            
            if row['budget_reset_at']:
                reset_seconds = (row['budget_reset_at'] - datetime.now()).total_seconds()
                if reset_seconds > 0:
                    self.metrics.budget_reset.labels(
                        entity_type=entity_type,
                        entity_id=entity_id,
                        entity_alias=entity_alias
                    ).set(reset_seconds)

    def update_key_metrics(self):
        results = self.db.execute_query(MetricQueries.get_key_metrics())
        
        for row in results:
            key_name = row['key_name'] or 'none'
            key_alias = row['key_alias'] or 'none'
            
            if row['expires']:
                expiry_seconds = (row['expires'] - datetime.now()).total_seconds()
                if expiry_seconds > 0:
                    self.metrics.key_expiry.labels(
                        key_name=key_name,
                        key_alias=key_alias
                    ).set(expiry_seconds)
            
            if row['spend']:
                self.metrics.key_spend.labels(
                    key_name=key_name,
                    key_alias=key_alias
                ).set(row['spend'])

    def update_all_metrics(self):
        try:
            self.update_spend_metrics()
            self.update_rate_limits()
            self.update_budget_metrics()
            self.update_key_metrics()
        except Exception as e:
            logger.error(f"Error updating metrics: {e}")

def main():
    # Initialize configurations
    metrics_config = MetricsConfig()
    db_config = DatabaseConfig()
    
    # Initialize connections and collectors
    db_connection = DatabaseConnection(db_config)
    metrics = LiteLLMMetrics()
    collector = MetricsCollector(db_connection, metrics, metrics_config)

    # Start the metrics server
    metrics_port = int(os.getenv('METRICS_PORT', '9090'))
    start_http_server(metrics_port)
    logger.info(f"Metrics server started on port {metrics_port}")
    logger.info(f"Using time windows: spend={metrics_config.spend_window}, "
               f"request={metrics_config.request_window}, error={metrics_config.error_window}")
    logger.info(f"Metrics update interval: {metrics_config.update_interval} seconds")

    # Update metrics based on configured interval
    while True:
        collector.update_all_metrics()
        time.sleep(metrics_config.update_interval)

if __name__ == '__main__':
    main()
