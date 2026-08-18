# Notification Golden AMI

This directory builds the OT-Micro Notification Golden AMI.

## Notification API startup

The Notification API is started by **Gunicorn**, matching the working Docker deployment:

```text
Gunicorn
  -> notification_api:app
  -> 0.0.0.0:8085
```

Systemd does **not** execute `python notification_api.py` directly.

The AMI does not install, enable, or start the obsolete ScyllaDB synchronization service.

## Services

Only these services are managed by the AMI:

- `elasticsearch.service`
- `notification-api.service`

The Notification API service uses:

```text
--workers 2
--threads 4
--timeout 60
```

and binds to:

```text
0.0.0.0:8085
```

## AWS network selection

Packer automatically selects the default VPC in the configured AWS region and an available default subnet in `us-east-1a`.

No subnet ID or security-group ID is hardcoded.

## Build

```bash
packer init .
packer validate .
packer build .
```

Or:

```bash
./packer-build.sh
```

## Package note

The AMI build does not require the `zip` command. The package was removed
from the OS package installation list because it is unavailable from the
selected Ubuntu repositories in the current Packer build environment.

## Ubuntu package compatibility

The build repairs and upgrades the base Ubuntu package state before installing
Python tooling. Java and jq are not installed because they are not required by
the current Notification AMI build; Elasticsearch 7.x supplies its required
runtime. This also avoids unnecessary GUI/JRE dependencies.
