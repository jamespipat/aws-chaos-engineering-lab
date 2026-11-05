module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.1"

  name     = var.name
  vpc_id   = var.vpc_id
  subnets  = var.subnet_ids
  internal = true

  enable_deletion_protection = false

  security_group_ingress_rules = {
    from_nodes = {
      from_port                    = 80
      to_port                      = 80
      ip_protocol                  = "tcp"
      description                  = "Synthetic clients on the lab nodes"
      referenced_security_group_id = var.node_security_group_id
    }
  }

  security_group_egress_rules = {
    to_nodes = {
      from_port                    = 30080
      to_port                      = 30080
      ip_protocol                  = "tcp"
      description                  = "API NodePort"
      referenced_security_group_id = var.node_security_group_id
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "api"
      }
    }
  }

  target_groups = {
    api = {
      name_prefix       = "api-"
      protocol          = "HTTP"
      port              = 30080
      target_type       = "instance"
      create_attachment = false
      health_check = {
        enabled             = true
        path                = "/healthz"
        port                = "30080"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
      }
    }
  }

  tags = var.tags
}

resource "aws_autoscaling_attachment" "api" {
  for_each = var.autoscaling_group_names

  autoscaling_group_name = each.value
  lb_target_group_arn    = module.alb.target_groups["api"].arn
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_nodes" {
  security_group_id            = var.node_security_group_id
  referenced_security_group_id = module.alb.security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 30080
  to_port                      = 30080
  description                  = "Internal ALB to API NodePort"
}
