locals {
  name_prefix = "aws-chaos-lab"
  namespace   = "aws-chaos-lab"
  tags = {
    Project     = "aws-chaos-lab"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  availability_zones = {
    az_a = {
      availability_zone = var.availability_zone_names["az_a"]
      nat_cidr          = "10.0.0.0/24"
      app_cidr          = "10.0.16.0/20"
      data_cidr         = "10.0.64.0/24"
    }
    az_b = {
      availability_zone = var.availability_zone_names["az_b"]
      nat_cidr          = "10.0.1.0/24"
      app_cidr          = "10.0.32.0/20"
      data_cidr         = "10.0.65.0/24"
    }
  }

  alarms = {
    logical-error-rate = {
      metric_name         = "LogicalErrorRate"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 5
      evaluation_periods  = 2
      statistic           = "Average"
      treat_missing_data  = "notBreaching"
      stop_condition      = true
    }
    logical-p95-safety = {
      metric_name         = "LogicalP95Milliseconds"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 2000
      evaluation_periods  = 2
      statistic           = "Average"
      treat_missing_data  = "notBreaching"
      stop_condition      = true
    }
    heartbeat = {
      metric_name         = "Heartbeat"
      comparison_operator = "LessThanThreshold"
      threshold           = 1
      evaluation_periods  = 2
      statistic           = "Minimum"
      treat_missing_data  = "breaching"
      stop_condition      = true
    }
    detection-latency = {
      metric_name         = "LogicalP95Milliseconds"
      comparison_operator = "GreaterThanThreshold"
      threshold           = var.detection_p95_ms
      evaluation_periods  = 2
      statistic           = "Average"
      treat_missing_data  = "notBreaching"
      stop_condition      = false
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "terraform_remote_state" "evidence" {
  backend = "s3"
  config = {
    bucket       = var.state_bucket
    key          = "aws-chaos-lab/lab/evidence/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}

check "account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.allowed_account_id
    error_message = "This stack only applies in the account named by allowed_account_id."
  }
}
