# Sanitized results

`results.json` holds the measured numbers from one run of this lab. It contains no account identifiers, endpoints, ARNs, or pod names.

Times are UTC. Logical success counts a request that returned 202, including one allowed retry. The configured delay and the measured client p95 are separate fields.

Keep raw journals, FIS output, and Kubernetes events in a gitignored folder such as `evidence/private/`.
