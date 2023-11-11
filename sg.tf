module "app_alb_sg" {
  create  = !var.create_only_elastic
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.stack}-app-lb-sg"
  description = "Application Load Balancer security group"
  vpc_id      = module.vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

}

module "autoscaling_sg" {
  create  = !var.create_only_elastic
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.stack}-app-auto-scaling-sg"
  description = "App Autoscaling group security group"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.app_alb_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]
}

module "elastic_ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.db_container_name}-ec2-sg"
  description = "Elastic Search EC2 Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Nginx HTTP Port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Nginx HTTPS Port"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_source_security_group_id = [
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Lambda to ElasticSearch HTTP Port"
      source_security_group_id = module.lambda_to_elastic_sg.security_group_id
    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Lambda to ElasticSearch HTTPS Port"
      source_security_group_id = module.lambda_to_elastic_sg.security_group_id
    }
  ]
  egress_rules = ["all-all"]
}

module "lambda_to_elastic_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.db_container_name}-lambda-sg"
  description = "Lambda Elastic Loader Security Group"
  vpc_id      = module.vpc.vpc_id

  egress_rules = ["all-all"]
}
