# Wikijs Deployment

Provides an extremely simple Wikijs deployment intended to run on a single EC2 instance.

The AWS infrastructure is created with Terraform and Ansible is used for provisioning. The setup uses a few containers which are coordinated using Docker Compose. A Systemd service controls the use of Compose. It is not a completely automated setup, but the whole process is documented.

SSL is not configured yet.

## Prerequisites

Install Terraform and Ansible on your platform. Due to the use of Ansible, if you use Windows, you'll need to run the process from WSL. The use of a virtualenv is recommended for Ansible. Install [just](https://github.com/casey/just) on your platform.

Configure your AWS credentials:
```
export AWS_ACCESS_KEY_ID=<your access key id>
export AWS_SECRET_ACCESS_KEY=<your secret access key>
export AWS_DEFAULT_REGION=<your region>
```

Provide the Postgres password by creating a `.env` file at the root of this directory, and populate it as follows:
```
WIKI_DOMAIN_NAME=<your domain name>
POSTGRES_PASSWORD=<password>
```

Ansible will copy the file to the EC2 instance and it will be used by `docker-compose`.

Create an SSH keypair for the instance:
```
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/mediawiki
```

## Provision

Kick the process off:
```
just wiki
```

This will run Terraform, then Ansible, which should result in Wikijs deployed on the EC2 instance.

Now go to your DNS provider and create an A record which points your domain to the elastic IP address assigned to the EC2 instance.

To confirm that the A record is available, you can use `dig A <your domain> @1.1.1.1 +noall +answer`.

## Wikijs Installation

The Wikijs instance should now be accessible at the domain address, though only on HTTP for now.

The installation for Wikijs is minimal. It only really involves setting up an administrative user and specifying the domain.

## Backup/Restore

Backup and restore scripts are provisioned on the instance. An archive is produced which contains a `pg_dumpall` database backup, along with the Wikijs data and config directories. The archive is then uploaded to S3.

To restore one of these backups, you can provision a new set of infrastructure using the process defined above. Then SSH to the instance and run the restore script at `/mnt/data/restore.sh <backup file name>`. This will pull the backup from S3 and restore the database and directories mentioned previously.
