# Backend <-> Infra Sync

## Overview
- **Infra repo** (`AWSSmokeTest`) provisions the AWS foundation (VPC, subnets, RDS, Redis, Amazon MQ, S3) and manages the EC2 host that will run CodeDeploy plus the backend service.
- **Backend repo** (`https://github.com/starxtechnologysolutions/Umigo`, module `umigoCrmBackend`) supplies the Spring Boot application artifact that CodeDeploy installs on EC2.
- CodePipeline (planned) will coordinate source -> build -> deploy, so keeping both repos aligned is essential.

## Repositories
| Purpose | Repository | Default Branch | Deploy Branch Today |
|---------|------------|----------------|---------------------|
| Infra | `AWSSmokeTest` | `main` | `main` |
| Backend | `starxtechnologysolutions/Umigo` | `main` | `backend/loginCRM` (in progress) |

## Branch and Tag Conventions
- **`main`** - always deployable; mirrors what is running in the target environment; protected.
- **`develop`** - shared integration branch for coordinated work across infra and backend.
- **`feature/<TaskID from kanban>-short-desc`** - short lived branches for planned work; squash merge into `develop`.
- **`hotfix/<TaskID from kanban>-short-desc`** - urgent fixes cut from `main`; merge back to both `main` and `develop`.
- **Tags** - promote backend releases with `backend-v<semver>` (for example `backend-v0.2.0`); tag both repos when a release goes live so CodePipeline can pin artifact and infra commits.
- Record the active backend tag and Maven version in `versions.json` (or below) whenever promoting.

## Artifact Flow (Target State)
1. CodePipeline Source stage monitors the backend repo (primary) and this infra repo (secondary).
2. CodeBuild runs `./mvnw clean verify` (tests) and `mvn -B clean package -DskipTests` for the artifact.
3. Spring Boot Maven plugin emits `target/umigoCrmBackend-<version>.jar`; buildspec renames and uploads to an S3 artifact bucket (`s3://umigo-artifacts/<branch>/<tag>/app.jar`).
4. CodeDeploy pulls the artifact, copies it to `/app/app.jar` on the EC2 instance, and runs lifecycle hooks to restart the Spring Boot service.

## Configuration Ownership
- **Terraform outputs (infra repo)** - VPC and subnet IDs, security groups, DB endpoints, Redis and MQ hosts, S3 bucket names, Secrets Manager ARNs, Parameter Store paths.
- **GitHub access (SSM)** - Store a GitHub PAT in SSM Parameter Store (for example `/shared/github/pat-readonly`; optionally keep environment-specific entries such as `/dev/github/pat`) so the EC2 bootstrap can clone the private repo (instance profile must allow `ssm:GetParameter`).
- **Database migrations (backend repo)** - Flyway tracks versioned SQL in `src/main/resources/db/migration`; EC2 bootstrap runs `./mvnw flyway:migrate` and developers can do the same locally.
- **Backend defaults (backend repo)** - `application.yaml`, `schema.sql`, Log4j2 config embedded in the jar.
- **Secrets** - Firebase service account JSON (`umigo.firebase.config.path`) and DB credentials come from Secrets Manager or Parameter Store; CodeDeploy hooks will place them on disk or export environment variables.
- **Runtime flags** - set `SPRING_PROFILES_ACTIVE`, `JAVA_OPTS`, and other overrides via CodeDeploy environment configuration.

## Coordinated Change Workflow
1. Create backend feature branch (`feature/<TaskID from kanban>-...`) and develop the change.
2. If infra adjustments are required (network, IAM, parameters), open a matching branch here and reference the backend branch or tag in the PR description.
3. Merge backend branch into `develop`; once validated in CI, promote to `main`, bump the Maven version if needed, and create a release tag (`backend-vX.Y.Z`).
4. Update infra repo (for example, `versions.json`, pipeline variables) with the new backend tag; merge into `main`.
5. CodePipeline consumes both commits, builds and promotes the tagged artifact, and CodeDeploy rolls it out.

## Runbooks and References
- `runbooks/dev-smoke-test.md` - manual validation steps (update with backend deployment checks).
- Future runbooks to add: deploy, rollback, log collection, DB restore tailored to `umigoCrmBackend`.
- Incident and operations communications: establish Slack channel (suggested `#umigo-devops`) for alerts and coordination.

Keep this document and the linked runbooks up to date as the pipeline and environments evolve.






- **Dev bootstrap note**: Backend repo lives separately; script skips env file/db seed/backend launch unless you clone it locally and pass -BackendPath.


- **Backend runtime parameters (SSM)** - `/dev/backend/SPRING_DATASOURCE_URL`, `/dev/backend/SPRING_REDIS_HOST`, and `/dev/backend/SPRING_REDIS_PORT` provide connection details for services; scripts and bootstrap export them as environment variables.
