module "ecs_cluster" {
  create = !var.create_only_elastic
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = var.cluster_name

  # Capacity provider - autoscaling groups
  default_capacity_provider_use_fargate = false
  autoscaling_capacity_providers = {
    asg_provider = {
      auto_scaling_group_arn         = module.autoscaling.autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
  }
}


module "app_ecs_service" {
  create = !var.create_only_elastic
  source = "terraform-aws-modules/ecs/aws//modules/service"

  # Service
  name                               = "${var.stack}-frontend-ecs-service"
  cluster_arn                        = var.create_only_elastic ? "" : module.ecs_cluster.arn
  enable_autoscaling                 = true
  network_mode                       = "bridge"
  deployment_minimum_healthy_percent = "100"

  # Task Definition
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 256

  runtime_platform = {
    "cpu_architecture" : "ARM64",
    "operating_system_family" : "LINUX"
  }

  capacity_provider_strategy = {
    ex-1 = {
      capacity_provider = var.create_only_elastic ? null : module.ecs_cluster.autoscaling_capacity_providers["asg_provider"].name
      weight            = 1
      base              = 1
    }
  }

  volume = {
    log = {}
  }

  # Container definition(s)
  container_definitions = {
    (var.application_name) = {
      image                    = aws_ecr_repository.default.repository_url
      readonly_root_filesystem = false
    }
    nginx = {
      image = aws_ecr_repository.nginx_repo.repository_url
      port_mappings = [
        {
          containerPort = var.application_port
          hostPort      = var.application_port
          protocol      = "tcp"
        }
      ]
      links : [
        var.application_name
      ]

      mount_points = [
        {
          sourceVolume  = "log",
          containerPath = "/var/log/nginx"
        }
      ]
      readonly_root_filesystem = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = var.create_only_elastic ? "" : element(module.app_alb.target_group_arns, 0)
      container_name   = "nginx"
      container_port   = var.application_port
    }
  }

  subnet_ids = module.vpc.public_subnets
  security_group_rules = {
    alb_http_ingress = {
      type                     = "ingress"
      from_port                = var.application_port
      to_port                  = var.application_port
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = module.app_alb_sg.security_group_id
    }
  }
}

