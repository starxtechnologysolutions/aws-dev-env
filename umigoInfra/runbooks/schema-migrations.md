# Flyway Migration Runbook

This runbook explains how database changes are managed with Flyway and how the shared configuration in AWS Systems Manager Parameter Store fits into that workflow.

## Overview

- Migrations live in `umigoCrmBackend/src/main/resources/db/migration/`.
- Cloud-init runs `./mvnw flyway:migrate` with `-Dflyway.baselineOnMigrate=true` so new hosts automatically create `flyway_schema_history` when the schema is pre-populated.
- Datasource and Redis connection settings are injected from Parameter Store:
  - `/${env}/backend/SPRING_DATASOURCE_URL`
  - `/${env}/backend/SPRING_REDIS_HOST`
  - `/${env}/backend/SPRING_REDIS_PORT`

## Preparing a Migration

1. **Generate SQL**  
   Add a new file in the migration directory. Name it sequentially, e.g. `V2__add_booking_table.sql`.

2. **Test Locally**  
   From `umigoCrmBackend/` run:
   ```bash
   ./mvnw -B -DskipTests flyway:info
   ./mvnw -B -DskipTests flyway:migrate
   ```
   Use a local database or a temporary schema so you do not touch shared environments during development.

3. **Review & Commit**  
   Include SQL changes and any related application updates in the pull request.

## Baseline Scenarios

If you need to re-baseline a non-empty database manually:

```bash
./mvnw -B -DskipTests \
  -Dflyway.url=jdbc:postgresql://<host>:<port>/<db>?sslmode=require \
  -Dflyway.user=<user> \
  -Dflyway.password=<password> \
  -Dflyway.baselineOnMigrate=true \
  flyway:migrate
```

Flyway creates `flyway_schema_history` at version `1` and continues with new migrations. Remove `-Dflyway.baselineOnMigrate=true` for normal runs.

## Parameter Store Notes

Terraform (`infra/terraform/parameters.tf`) provisions the shared parameters. To inspect values:

```bash
aws ssm get-parameter --name "/${env}/backend/SPRING_DATASOURCE_URL" \
  --region <region> --query Parameter.Value --output text
```

Update Terraform when new shared settings are required so all environments stay consistent. Avoid editing parameters manually in the console unless responding to an incident; if you must, follow up with a Terraform change.

## Post-Deployment Verification

After Terraform or cloud-init runs, confirm migrations succeeded:

```bash
ssh ec2-user@<host>
sudo tail -n 50 /var/log/umigo-bootstrap.log
```

Look for `BUILD SUCCESS` and `Bootstrap completed`. For additional checks, run `./mvnw flyway:info` from `/home/ec2-user/umigo/umigoCrmBackend`.