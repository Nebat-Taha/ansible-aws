# Multi-Region Configuration Automation with Ansible

Ansible-based configuration automation for MongoDB and Redis across multiple AWS regions, with GitHub Actions orchestration and cross-cloud backup and recovery using Backblaze B2.

The implementation combines dynamic inventory, reusable Ansible roles, region-based workflow matrices, and targeted restore operations. Terraform provisions the underlying infrastructure, while Ansible manages database configuration and data operations.

## Architecture

```text
                    GitHub Actions
                 (workflow orchestration)
                           |
                  Regional Matrix Jobs
                     /           \
                us-east-1      eu-central-1
                    |               |
              Dynamic Inventory / AWS EC2
                    |               |
              MongoDB Host     Redis Host
                    |               |
              Ansible Roles   Ansible Roles
              Setup / Backup  Setup / Backup
                    |               |
                    +-------+-------+
                            |
                      Backblaze B2
                   Cross-cloud backup
                            |
                     Restore Workflow
                            |
                  Selected Database Host

Terraform provisions infrastructure.
Ansible applies configuration and manages data operations.
```

## Capabilities

- **Multi-region configuration:** Reuse the same Ansible playbooks and GitHub Actions workflow logic across AWS regions.
- **Dynamic inventory:** Discover EC2 instances at runtime using AWS metadata, service tags, and region-based groups.
- **Consistent desired state:** Reapply database configuration when hosts are recreated, configuration changes, or drift needs to be reconciled.
- **Reusable Ansible roles:** Separate MongoDB and Redis setup, backup, and restore operations into database-specific roles.
- **Cross-cloud backups:** Upload database backup artifacts from AWS instances to Backblaze B2.
- **Targeted restoration:** Select a database type, region, destination host, and backup filename for a restore operation.
- **Ephemeral automation:** Use GitHub-hosted runners as on-demand Ansible control nodes rather than maintaining a dedicated, continuously running controller for the demonstration.
- **Flexible execution:** Run workflows manually or enable the existing commented schedule configuration when recurring execution is desired.

## Implementation

### Dynamic inventory and regional targeting

The AWS EC2 inventory plugin discovers running instances and builds inventory groups from their `Service` tags and AWS regions.

The playbooks use service and region group intersections to target the intended database hosts. This avoids maintaining separate static inventories and allows configuration operations to follow the instances currently deployed in AWS.

### Configuration management

The setup playbook, `ansible/playbooks/site.yml`, invokes the MongoDB and Redis setup roles.

The roles manage database installation and configuration, including their configured local bind settings. Keeping configuration separate from infrastructure provisioning allows the desired state to be applied again whenever the underlying hosts are rebuilt or need to be reconciled.

### Multi-region workflow orchestration

GitHub Actions matrix strategies reuse workflow definitions across `us-east-1` and `eu-central-1`.

The workflows handle the execution context for each region, including AWS authentication, instance discovery, temporary SSH access, and Ansible execution. This reduces duplicated workflow logic while keeping regional operations independently addressable.

### Cross-cloud backup

The backup playbook, `ansible/playbooks/backup.yml`, invokes database-specific backup roles.

| Database | Backup implementation |
|---|---|
| MongoDB | Creates a compressed archive using `mongodump` |
| Redis | Triggers an RDB snapshot and uploads the resulting file |

The roles upload backup artifacts to Backblaze B2 and remove temporary local backup files from the database instances after the upload task completes. Backup retention is managed on the B2 side.

The backup workflow supports manual execution. Its schedule configuration can be enabled to support recurring backups.

### Targeted restore operations

Restoration is implemented as a separate workflow rather than being mixed into routine configuration or backup execution.

The operator selects the database type, AWS region, target host, and backup filename. The workflow constructs a runtime inventory for the selected host and invokes the corresponding Ansible restore role.

- **MongoDB:** Downloads the selected archive from B2 and restores it using `mongorestore --drop`.
- **Redis:** Stops the Redis service, retrieves the selected RDB file, places it in the configured data directory, restarts Redis, and performs the role's configured verification check.

This makes the recovery point and destination explicit for each restore operation.

## Coordinated recovery workflow

The project coordinates infrastructure provisioning, configuration management, and data restoration through three independently executable stages.

1. **Provision infrastructure:** Use Terraform to create the required regional resources.
2. **Apply configuration:** Run the Ansible setup workflow to establish the intended database configuration on the target hosts.
3. **Restore data:** Run the restore workflow to retrieve a selected database backup from Backblaze B2.

This provides a repeatable path to build the environment from scratch, reapply configuration to reconcile drift, or extend the deployment to additional regions.

### Separation of configuration and routine operations

Configuration, backup, and restoration are implemented as separate workflows, each with a distinct operational purpose.

The setup workflow applies the desired database configuration when infrastructure is created, configuration needs to be reapplied, or changes need to be reconciled. The backup workflow operates independently, allowing database data to be backed up without rerunning configuration tasks or coupling routine backups to configuration changes. Restoration is also isolated in its own workflow because it targets a specific recovery point and destination.

This separation keeps routine data protection independent of configuration management, avoids unnecessary configuration runs during backups, and allows each operation to be executed on its own schedule or when required.


## Repository structure

```text
.
├── .github/
│   └── workflows/
│       ├── ansible-multi-region-setup.yml
│       ├── ansible-multi-region-backup.yml
│       ├── ansible-db-restore.yml
│       └── ...
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── aws_ec2.yml
│   ├── playbooks/
│   │   ├── site.yml
│   │   ├── backup.yml
│   │   └── restore.yml
│   └── roles/
│       ├── mongodb_setup/
│       ├── mongodb_backup/
│       ├── mongodb_restore/
│       ├── redis_setup/
│       ├── redis_backup/
│       └── redis_restore/
└── terraform/
    ├── global/
    ├── modules/
    └── regions/
```

## Technology stack

| Technology | Responsibility |
|---|---|
| Ansible | Configuration management, backup, and restore |
| GitHub Actions | Workflow orchestration and regional matrix execution |
| AWS EC2 dynamic inventory | Runtime host discovery and regional targeting |
| AWS IAM and GitHub OIDC | Workflow authentication to AWS |
| EC2 Instance Connect | Temporary SSH access for setup and backup workflows |
| Amazon EC2 | Database hosts |
| MongoDB tools | Database backup and restoration |
| Redis RDB | Snapshot-based backup and restoration |
| Backblaze B2 | External backup storage and restore source |
| Terraform | Infrastructure provisioning |

## Configuration

The workflows rely on an AWS role trusted by GitHub Actions OIDC, suitable permissions for instance discovery and EC2 Instance Connect, and credentials for Backblaze B2.

The repository uses the following GitHub secrets for the relevant workflows:

- `AWS_ROLE_ARN`
- `BACKBLAZE_APPLICATION_KEY_ID`
- `BACKBLAZE_APPLICATION_KEY`
- `SSH_PRIVATE_KEY` for the restore workflow

Configure these values for the target environment before running the workflows. The B2 bucket name and some infrastructure-specific values are defined in the repository and should be reviewed when adapting the implementation.

## Related work

Terraform is included to support the complete infrastructure-to-recovery workflow. The focus of this repository is Ansible configuration automation, regional execution, and database backup and restoration.

