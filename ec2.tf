locals {
  # Install Elasticsearch
  # Sets up Nginx and SSL certification
  user_data_elastic = <<-EOF
    #!/bin/bash
    set -ex
    sudo yum update -y
    sudo yum install java-1.8.0 -y
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.9.1-aarch64.rpm
    rpm --install elasticsearch-8.9.1-aarch64.rpm
    rm -f elasticsearch-8.9.1-aarch64.rpm

    sudo amazon-linux-extras install nginx1 -y

    sed -i 's/#cluster.name: my-application/cluster.name: nba-play-db-cluster/g' /etc/elasticsearch/elasticsearch.yml
    sed -i 's/enabled: true/enabled: false/g' /etc/elasticsearch/elasticsearch.yml
    sed -i 's/xpack.security.enabled: false/xpack.security.enabled: true/g' /etc/elasticsearch/elasticsearch.yml

    aws s3 cp s3://nba-event-db/nginx/ssl-certs/ /etc/elasticsearch/certs/elastic.nbaplaydb.com/ --recursive
    aws s3 cp s3://nba-event-db/nginx/elastic.nbaplaydb.com.conf /etc/nginx/conf.d/elastic.nbaplaydb.com.conf

    mkdir -p /etc/letsencrypt/
    curl https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf --output /etc/letsencrypt/options-ssl-nginx.conf

    systemctl daemon-reload
    systemctl enable elasticsearch.service
    systemctl start elasticsearch.service

    systemctl enable nginx.service
    systemctl start nginx.service
  EOF

  user_data_asg = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${var.cluster_name}
    ECS_LOGLEVEL=debug
    ECS_ENABLE_TASK_IAM_ROLE=true
    EOF
  EOT
}

data "aws_default_tags" "default_tags" {}

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended"
}

module "app_alb" {
  create_lb = !var.create_only_elastic
  source    = "terraform-aws-modules/alb/aws"
  version   = "~> 8.0"

  name = "${var.application_name}-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.app_alb_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = var.application_port
      protocol           = "HTTP"
      target_group_index = 0
    },
  ]

  target_groups = [
    {
      name             = "${var.stack}-app-target-group"
      backend_protocol = "HTTP"
      backend_port     = var.application_port
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/elb-status"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    },
  ]
}

module "autoscaling" {
  create                     = !var.create_only_elastic
  create_launch_template     = !var.create_only_elastic
  source                     = "terraform-aws-modules/autoscaling/aws"
  version                    = "~> 6.10"
  instance_type              = var.instance_type
  use_mixed_instances_policy = false
  mixed_instances_policy     = {}

  name = "${var.stack}-instance"

  image_id = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]

  security_groups = [module.autoscaling_sg.security_group_id]
  user_data       = base64encode(local.user_data_asg)

  create_iam_instance_profile = var.create_only_elastic ? false : true
  iam_role_name               = "${var.stack}-auto-scaling-iam-role"
  iam_role_description        = "ECS role for ${var.stack}"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonS3ReadOnlyAccess              = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  vpc_zone_identifier = module.vpc.public_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }

  protect_from_scale_in = true

  instance_refresh = {
    strategy = "Rolling"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

