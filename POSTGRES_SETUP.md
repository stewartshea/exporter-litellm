# PostgreSQL Read-Only User Setup for LiteLLM Exporter

This guide explains how to create a dedicated read-only PostgreSQL user for the LiteLLM exporter. Following the principle of least privilege, the exporter only needs read access to collect metrics.

## Creating the Read-Only User

Connect to your PostgreSQL database as a superuser (usually 'postgres') and run the following commands:

```sql
-- Create a new user for the exporter
CREATE USER litellm_exporter WITH PASSWORD 'your_secure_password';

-- Connect to the LiteLLM database
\c litellm

-- Grant CONNECT privilege on the database
GRANT CONNECT ON DATABASE litellm TO litellm_exporter;

-- Grant USAGE privilege on the schema
GRANT USAGE ON SCHEMA public TO litellm_exporter;

-- Grant SELECT privilege on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO litellm_exporter;

-- Grant SELECT privilege on all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO litellm_exporter;
```

## Using the Read-Only User

Update your exporter configuration with the new user credentials:

```yaml
# In docker-compose.yml
environment:
  - LITELLM_DB_USER=litellm_exporter
  - LITELLM_DB_PASSWORD=your_secure_password
```

Or if running locally:

```bash
export LITELLM_DB_USER=litellm_exporter
export LITELLM_DB_PASSWORD=your_secure_password
```

## Verifying Permissions

To verify the user has the correct permissions:

1. Connect as the new user:
```bash
psql -U litellm_exporter -h your_host -d litellm
```

2. Try to read from a table:
```sql
SELECT COUNT(*) FROM "LiteLLM_SpendLogs";
```

3. Verify write operations fail:
```sql
-- These should fail with permission denied
INSERT INTO "LiteLLM_SpendLogs" (column) VALUES ('test');
UPDATE "LiteLLM_SpendLogs" SET column = 'test';
DELETE FROM "LiteLLM_SpendLogs";
```

## Security Considerations

1. Use a strong password for the exporter user
2. Consider network-level restrictions (pg_hba.conf) to limit which hosts can connect
3. Regularly rotate the password
4. Monitor failed login attempts
5. Consider using SSL for database connections

## Revoking Access

If needed, you can revoke the user's access:

```sql
-- Revoke all privileges
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM litellm_exporter;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM litellm_exporter;
REVOKE ALL PRIVILEGES ON DATABASE litellm FROM litellm_exporter;

-- Drop the user
DROP USER litellm_exporter;
```

## Troubleshooting

### Common Issues

1. Connection refused
   - Check if the user has CONNECT privilege on the database
   - Verify pg_hba.conf allows connections from the exporter's host

2. Permission denied for relation
   - Ensure SELECT privilege is granted on the specific table
   - Check if the table was created after granting default privileges

3. SSL required
   - Add `?sslmode=require` to the connection string if SSL is required
   - Ensure proper SSL certificates are configured

### Useful Diagnostic Queries

Check user permissions:
```sql
-- List all privileges for the exporter user
SELECT * FROM information_schema.table_privileges 
WHERE grantee = 'litellm_exporter';

-- Check schema access
SELECT * FROM information_schema.role_usage_grants 
WHERE grantee = 'litellm_exporter';
```

## Best Practices

1. Create separate read-only users for different environments (dev, staging, prod)
2. Document all permission changes in your change management system
3. Include the user creation in your database initialization scripts
4. Regularly audit database access and permissions
5. Use connection pooling to manage database connections efficiently
