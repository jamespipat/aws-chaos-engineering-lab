locals {
  database_env = {
    AWS_REGION       = var.region
    DATABASE_HOST    = local.platform.database_host
    DATABASE_PORT    = tostring(local.platform.database_port)
    DATABASE_NAME    = local.platform.database_name
    DATABASE_SSLMODE = "verify-full"
    RDS_CA_PATH      = "certs/global-bundle.pem"
  }

  services = {
    api = {
      command              = "api"
      replicas             = 2
      service_account_name = "api"
      requests_cpu         = "250m"
      requests_memory      = "256Mi"
      limits_cpu           = "1"
      limits_memory        = "512Mi"
      pdb_min_available    = 1
      env = merge(local.database_env, {
        DATABASE_USER = "api"
      })
      service = {
        type      = "NodePort"
        port      = 80
        node_port = 30080
      }
    }
    worker = {
      command              = "worker"
      replicas             = 1
      service_account_name = "worker"
      requests_cpu         = "100m"
      requests_memory      = "128Mi"
      limits_cpu           = "500m"
      limits_memory        = "256Mi"
      pdb_min_available    = null
      env = merge(local.database_env, {
        DATABASE_USER = "worker"
        SQS_QUEUE_URL = local.platform.queue_url
      })
      service = null
    }
    collector = {
      command              = "collector"
      replicas             = 1
      service_account_name = "collector"
      requests_cpu         = "100m"
      requests_memory      = "128Mi"
      limits_cpu           = "500m"
      limits_memory        = "256Mi"
      pdb_min_available    = null
      env = {
        AWS_REGION      = var.region
        EVIDENCE_BUCKET = local.platform.evidence_bucket_name
        RUN_ID          = var.run_id
      }
      service = {
        type      = "ClusterIP"
        port      = 8080
        node_port = null
      }
    }
  }

  admin_jobs = merge(
    {
      migrate = {
        command              = "migrate"
        service_account_name = "migrate"
        wait_for_completion  = true
        env = merge(local.database_env, {
          DATABASE_MASTER_SECRET_ARN = local.platform.database_master_secret_arn
        })
      }
    },
    var.enable_verify_job ? {
      verify = {
        command              = "verify"
        service_account_name = "verifier"
        wait_for_completion  = true
        env = merge(local.database_env, {
          DATABASE_USER   = "verifier"
          EVIDENCE_BUCKET = local.platform.evidence_bucket_name
          EVIDENCE_PREFIX = var.evidence_prefix
        })
      }
    } : {}
  )
}
