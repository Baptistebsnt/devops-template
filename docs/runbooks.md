# Operational Runbooks

This document contains runbooks for common operational tasks and procedures.

## Database Operations

### Creating a Database Backup

```bash
# Navigate to the scripts directory
cd scripts/database

# Create a backup
./db_operations.sh backup
```

The backup will be stored in the `backups` directory with a timestamp.

### Restoring from a Backup

```bash
# List available backups
./db_operations.sh list

# Restore from a specific backup
./db_operations.sh restore backups/db_backup_20240101_120000.sql
```

### Verifying a Backup

```bash
# Verify a specific backup
./db_operations.sh verify backups/db_backup_20240101_120000.sql
```

## Deployment Operations

### Deploying to Development

1. Ensure you're on the development branch:

   ```bash
   git checkout development
   ```

2. Pull latest changes:

   ```bash
   git pull origin development
   ```

3. Run deployment verification:

   ```bash
   ./scripts/tests/verify_deployment.sh
   ```

4. Deploy using the deployment script:
   ```bash
   ./scripts/deploy.sh dev
   ```

### Deploying to Production

1. Create a release branch:

   ```bash
   git checkout -b release/v1.x.x
   ```

2. Update version numbers and changelog

3. Create a pull request to main branch

4. After PR approval and merge:

   ```bash
   git checkout main
   git pull origin main
   ```

5. Run deployment verification:

   ```bash
   ./scripts/tests/verify_deployment.sh
   ```

6. Deploy to production:
   ```bash
   ./scripts/deploy.sh prod
   ```

## Monitoring Operations

### Checking System Health

1. Access Grafana dashboard:

   ```bash
   # URL: http://localhost:3000
   # Default credentials: admin/admin
   ```

2. Check key metrics:
   - CPU Usage
   - Memory Usage
   - Disk Space
   - Network Traffic
   - Application Response Time

### Viewing Logs

1. Access Kibana:

   ```bash
   # URL: http://localhost:5601
   ```

2. Common log queries:
   ```json
   {
     "query": {
       "bool": {
         "must": [
           { "match": { "level": "ERROR" } },
           { "range": { "@timestamp": { "gte": "now-1h" } } }
         ]
       }
     }
   }
   ```

## Incident Response

### Service Outage

1. Initial Assessment:

   - Check monitoring dashboards
   - Verify service health endpoints
   - Review recent deployments

2. Communication:

   - Update status page
   - Notify team via Slack
   - Create incident ticket

3. Investigation:

   - Check application logs
   - Verify database connectivity
   - Review system metrics

4. Resolution:
   - Apply fixes or rollback if needed
   - Verify service recovery
   - Document incident details

### Database Issues

1. Check Database Status:

   ```bash
   ./scripts/database/db_operations.sh status
   ```

2. Verify Connectivity:

   ```bash
   ./scripts/database/db_operations.sh test-connection
   ```

3. If needed, restore from backup:
   ```bash
   ./scripts/database/db_operations.sh restore <backup_file>
   ```

## Maintenance Procedures

### System Updates

1. Schedule maintenance window
2. Notify stakeholders
3. Create backup:

   ```bash
   ./scripts/database/db_operations.sh backup
   ```

4. Apply updates:

   ```bash
   ./scripts/update.sh
   ```

5. Verify system health:
   ```bash
   ./scripts/tests/verify_deployment.sh
   ```

### Certificate Renewal

1. Generate new certificates:

   ```bash
   ./scripts/security/renew_certificates.sh
   ```

2. Deploy new certificates:

   ```bash
   ./scripts/security/deploy_certificates.sh
   ```

3. Verify certificate installation:
   ```bash
   ./scripts/security/verify_certificates.sh
   ```

## Security Procedures

### Access Management

1. Adding new team member:

   - Create GitHub account
   - Add to appropriate teams
   - Set up 2FA
   - Provide access to necessary tools

2. Removing team member:
   - Revoke GitHub access
   - Remove from team channels
   - Rotate shared credentials

### Security Incident Response

1. Initial Assessment:

   - Identify affected systems
   - Isolate compromised components
   - Preserve evidence

2. Containment:

   - Block malicious IPs
   - Reset compromised credentials
   - Apply security patches

3. Recovery:

   - Restore from clean backups
   - Verify system integrity
   - Update security measures

4. Post-Incident:
   - Document incident
   - Update security procedures
   - Conduct security review
