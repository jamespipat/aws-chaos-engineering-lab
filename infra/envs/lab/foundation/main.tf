module "registry" {
  source = "../../../modules/artifact-registry"

  name = local.name_prefix
  tags = local.tags
}

module "boundary" {
  source = "../../../modules/permissions-boundary"

  name = local.name_prefix
  tags = local.tags
}

module "network" {
  source = "../../../modules/network"

  name               = local.name_prefix
  cidr_block         = "10.0.0.0/16"
  availability_zones = local.availability_zones
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "observability" {
  source = "../../../modules/observability"

  name_prefix        = local.name_prefix
  log_retention_days = var.log_retention_days
  alarms             = local.alarms
  tags               = local.tags
}

module "queue" {
  source = "../../../modules/work-queue"

  name = local.name_prefix
  tags = local.tags
}

module "fis_execution_role" {
  source = "../../../modules/fis-execution-role"

  name                     = "${local.name_prefix}-fis"
  account_id               = data.aws_caller_identity.current.account_id
  region                   = var.region
  cluster_name             = local.name_prefix
  alarm_arns               = module.observability.stop_condition_alarm_arns
  log_group_arn            = module.observability.log_group_arns.fis
  permissions_boundary_arn = module.boundary.arn
  tags                     = local.tags
}

module "cluster" {
  source = "../../../modules/cluster"

  name                         = local.name_prefix
  kubernetes_version           = "1.34"
  vpc_id                       = module.network.vpc_id
  default_vpc_id               = data.aws_vpc.default.id
  subnet_ids                   = module.network.app_subnet_id_list
  endpoint_public_access_cidrs = [var.operator_cidr]
  fis_role_arn                 = module.fis_execution_role.arn
  tags                         = local.tags

  node_groups = {
    for key, subnet_id in module.network.app_subnet_ids : key => {
      subnet_id         = subnet_id
      instance_type     = var.instance_type
      availability_zone = local.availability_zones[key].availability_zone
    }
  }
}

module "database" {
  source = "../../../modules/database"

  name                   = local.name_prefix
  vpc_id                 = module.network.vpc_id
  subnet_group_name      = module.network.database_subnet_group_name
  node_security_group_id = module.cluster.node_security_group_id
  instance_class         = "db.t4g.small"
  engine_version         = var.engine_version
  multi_az               = var.multi_az
  deletion_protection    = false
  skip_final_snapshot    = true
  tags                   = local.tags
}

module "edge" {
  source = "../../../modules/edge"

  name                    = local.name_prefix
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.app_subnet_id_list
  node_security_group_id  = module.cluster.node_security_group_id
  autoscaling_group_names = module.cluster.autoscaling_group_names
  tags                    = local.tags
}

module "budget" {
  source = "../../../modules/budget-guardrail"

  name               = local.name_prefix
  limit_usd          = var.budget_limit_usd
  notification_email = var.budget_notification_email
  tags               = local.tags
}

locals {
  db_user_arn_prefix = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.database.resource_id}"
  evidence_bucket    = data.terraform_remote_state.evidence.outputs.bucket_name
  identities = {
    api = {
      service_account_name = "api"
      permissions = {
        connect = {
          actions   = ["rds-db:connect"]
          resources = ["${local.db_user_arn_prefix}/api"]
          condition = null
        }
      }
    }
    worker = {
      service_account_name = "worker"
      permissions = {
        connect = {
          actions   = ["rds-db:connect"]
          resources = ["${local.db_user_arn_prefix}/worker"]
          condition = null
        }
        queue = {
          actions = [
            "sqs:SendMessage",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
            "sqs:GetQueueUrl",
            "sqs:ChangeMessageVisibility",
          ]
          resources = [module.queue.queue_arn]
          condition = null
        }
      }
    }
    collector = {
      service_account_name = "collector"
      permissions = {
        journal = {
          actions   = ["s3:PutObject"]
          resources = ["arn:aws:s3:::${local.evidence_bucket}/journal/*"]
          condition = null
        }
        metrics = {
          actions   = ["cloudwatch:PutMetricData"]
          resources = ["*"]
          condition = [{
            test     = "StringEquals"
            variable = "cloudwatch:namespace"
            values   = ["ChaosLab"]
          }]
        }
      }
    }
    log_shipper = {
      service_account_name = "log-shipper"
      permissions = {
        logs = {
          actions = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
          ]
          resources = [
            module.observability.log_group_arns.application,
            "${module.observability.log_group_arns.application}:*",
          ]
          condition = null
        }
      }
    }
    verifier = {
      service_account_name = "verifier"
      permissions = {
        connect = {
          actions   = ["rds-db:connect"]
          resources = ["${local.db_user_arn_prefix}/verifier"]
          condition = null
        }
        journal = {
          actions = ["s3:GetObject", "s3:ListBucket"]
          resources = [
            "arn:aws:s3:::${local.evidence_bucket}",
            "arn:aws:s3:::${local.evidence_bucket}/journal/*",
          ]
          condition = null
        }
      }
    }
    migrate = {
      service_account_name = "migrate"
      permissions = {
        mastersecret = {
          actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
          resources = [module.database.master_secret_arn]
          condition = null
        }
      }
    }
  }
}

module "workload_identity" {
  source   = "../../../modules/workload-identity"
  for_each = local.identities

  name                     = "${local.name_prefix}-${each.key}"
  namespace                = local.namespace
  service_account_name     = each.value.service_account_name
  oidc_provider_arn        = module.cluster.oidc_provider_arn
  permissions_boundary_arn = module.boundary.arn
  permissions              = each.value.permissions
  tags                     = local.tags
}
