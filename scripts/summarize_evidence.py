#!/usr/bin/env python3
"""Summarize journal JSONL files for one lab run. Prints counts and percentiles."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def parse_time(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def percentile(values: list[int], fraction: float) -> int:
    if not values:
        return 0
    ordered = sorted(values)
    index = max(0, int(len(ordered) * fraction + 0.999999) - 1)
    return ordered[index]


def load(paths: list[Path]) -> list[dict]:
    rows = []
    for path in paths:
        for line in path.read_text().splitlines():
            if line.strip():
                rows.append(json.loads(line))
    return rows


def summarize(rows: list[dict], start: datetime | None, end: datetime | None) -> dict:
    selected = []
    for row in rows:
        started = parse_time(row["started_at"])
        if start and started < start:
            continue
        if end and started >= end:
            continue
        selected.append(row)
    latencies = [int(row["latency_ms"]) for row in selected]
    successes = [row for row in selected if int(row["status"]) == 202]
    first = [row for row in successes if int(row["retry_count"]) == 0]
    return {
        "requests": len(selected),
        "logical_success": len(successes),
        "logical_success_rate": (len(successes) / len(selected)) if selected else 0,
        "first_attempt_success": len(first),
        "first_attempt_success_rate": (len(first) / len(selected)) if selected else 0,
        "p95_ms": percentile(latencies, 0.95),
        "p99_ms": percentile(latencies, 0.99),
    }


def main() -> None:
    directory = Path(sys.argv[1])
    rows = load(sorted(directory.glob("*.jsonl")))
    windows = json.loads(Path(sys.argv[2]).read_text()) if len(sys.argv) > 2 else {"all": {}}
    report = {}
    for name, bounds in windows.items():
        start = parse_time(bounds["start"]) if bounds.get("start") else None
        end = parse_time(bounds["end"]) if bounds.get("end") else None
        report[name] = summarize(rows, start, end)
    json.dump(report, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
