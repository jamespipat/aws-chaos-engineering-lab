# Third-party notices

The MIT license in `LICENSE` covers only the original code in this repository. Other material keeps its own terms.

- **Amazon RDS certificate bundle.** `app/certs/global-bundle.pem` is the public certificate bundle AWS publishes for TLS connections to RDS: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html.
- **Terraform modules and providers.** Downloaded at `terraform init` under their own licenses, including `terraform-aws-modules` (Apache 2.0) and the HashiCorp providers (MPL 2.0).
- **npm dependencies.** Installed from `package-lock.json` under their own licenses, including the AWS SDK for JavaScript (Apache 2.0) and `pg` (MIT).
- **AWS service names.** AWS and the AWS service names are trademarks of Amazon.com, Inc. or its affiliates.
- **AWS architecture icons.** The diagrams in `docs/diagrams/` embed SVG assets from the July 31, 2026 [AWS Architecture Icons package](https://aws.amazon.com/architecture/icons/), checked on November 5, 2026. The package SHA-256 is `d2d166c453526471749d520e0db022c459abef759d2946cf2dd1d1c992dc6526`. These AWS assets retain their own terms and are not covered by this repository's MIT license.
- **Container images.** `node:22-bookworm-slim`, `grafana/k6`, and the AWS FIS pod image are pulled at runtime under their own terms.
