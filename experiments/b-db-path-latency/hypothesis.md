# Experiment B

Action: `aws:eks:pod-network-latency` on one API pod for `PT2M`, delay 100 ms, jitter 10 ms, sources set to the RDS hostname. Do not run packet loss on that pod at the same time.

Detection target: two consecutive one-minute windows whose logical p95 is more than 50 ms above the baseline. That alarm does not stop the experiment.

Recovery target: the first of three consecutive minutes with at least 99 percent logical success and logical p95 below the greater of baseline times 1.2 and baseline plus 25 ms. That start is within 120 seconds after the fault ends.

This experiment does not claim automatic failover.

Status: PENDING LAB.
