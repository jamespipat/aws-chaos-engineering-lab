# Sources

Checked against official AWS pages on 2026-11-05.

## Lab building blocks

- AWS FIS actions: https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html
- AWS FIS EKS pod actions: https://docs.aws.amazon.com/fis/latest/userguide/eks-pod-actions.html
- AWS FIS target preview: https://docs.aws.amazon.com/fis/latest/userguide/generate-target-preview.html
- AWS FIS safety lever: https://docs.aws.amazon.com/fis/latest/userguide/safety-lever.html
- AWS FIS stop conditions: https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html
- Terraform FIS experiment template: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fis_experiment_template
- Terraform S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3

## Chaos engineering and AWS resilience services

- Experiment loop of steady state, hypothesis, limited fault, observe, and improve: https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_testing_resiliency_failure_injection_resiliency.html
- Retries can amplify load: https://aws.amazon.com/builders-library/timeouts-retries-and-backoff-with-jitter/
- FIS experiment templates: https://docs.aws.amazon.com/fis/latest/userguide/experiment-templates.html
- FIS experiment reports: https://docs.aws.amazon.com/fis/latest/userguide/experiment-report-configuration.html
- FIS scenario library: https://docs.aws.amazon.com/fis/latest/userguide/scenario-library-scenarios.html
- FIS multi-account experiments: https://docs.aws.amazon.com/fis/latest/userguide/multi-account.html
- FIS scheduling with EventBridge Scheduler: https://docs.aws.amazon.com/fis/latest/userguide/experiment-scheduler.html
- Not every FIS action can be undone by stopping: https://docs.aws.amazon.com/fis/latest/userguide/action-sequence.html#action-parameters
- Resilience Hub policies with RTO and RPO: https://docs.aws.amazon.com/resilience-hub/latest/userguide/create-policy.html
- Next-generation Resilience Hub, May 28, 2026: https://aws.amazon.com/about-aws/whats-new/2026/05/aws-announces-next-gen-aws-resilience-hub/
- Resilience Hub recommended tests, August 3, 2026: https://aws.amazon.com/about-aws/whats-new/2026/08/aws-resilience-hub/ and https://aws.amazon.com/blogs/architecture/recommended-resilience-testing-in-the-next-generation-of-aws-resilience-hub/
- ARC zonal shift: https://docs.aws.amazon.com/r53recovery/latest/dg/arc-zonal-shift.html
- ARC zonal autoshift: https://docs.aws.amazon.com/r53recovery/latest/dg/arc-zonal-autoshift.html
- ARC routing controls: https://docs.aws.amazon.com/r53recovery/latest/dg/routing-control.html
- ARC readiness checks closed to new customers since April 30, 2026: https://docs.aws.amazon.com/r53recovery/latest/dg/arc-readiness-availability-change.html

This lab used FIS, CloudWatch, EKS, RDS, SQS, and S3. It did not use Resilience Hub or ARC.
