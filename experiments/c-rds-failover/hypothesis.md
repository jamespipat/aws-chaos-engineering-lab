# Experiment C

Not in the first catalog. It requires a reviewed Multi-AZ change and a separate FIS role for `aws:rds:reboot-db-instances` with `forceFailover=true`.

`aws:rds:failover-db-cluster` targets an Aurora cluster and is not the action for this PostgreSQL instance.

Status: NOT RUN.
