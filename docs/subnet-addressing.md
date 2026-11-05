# Subnet addresses

`terraform-aws-modules/vpc/aws` version `6.7.3` creates its public, private, and database subnets with `count`, so each subnet's address is its position in a list.

The network module builds those lists from the catalog keys in order. Its variable only accepts the prefix `az_a`, `az_b`, `az_c`, and so on, so index 0 is always `az_a`.

Adding `az_c` at the end keeps the existing indexes. Inserting, removing, or reordering a key changes the CIDR at an existing index and replaces subnets. Treat that as a failed review even if a `moved` block could be written.

The example catalog uses `10.0.0.0/16` with one `/24` public subnet, one `/20` private subnet, and one `/24` data subnet per AZ. Change those values in `infra/envs/lab/foundation/catalog.tf` before the first apply if they overlap a network you use.
