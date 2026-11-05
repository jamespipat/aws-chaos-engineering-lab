# Experiment A

Action: `aws:eks:pod-delete` on one API pod, `gracePeriodSeconds=0`, `COUNT(1)`.

These are targets, not results:

- At least 99 percent logical success during the 120 seconds after the actual delete.
- Logical p95 under 750 ms in that same window.
- Replacement pod Ready within 90 seconds.
- Every acknowledged write still has one database row and one processed effect.
- First-attempt success is reported separately.

Logical success means HTTP 202 within five seconds. One retry is allowed after a transport failure or 429, 502, 503, or 504. Logical latency includes that retry. A missing journal record invalidates the run.

Status: PENDING LAB.
