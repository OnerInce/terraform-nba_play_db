variable "region" {
  type        = string
  description = "AWS Region to Deploy whole stack"
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to run application"
}

variable "stack" {
  type        = string
  description = "Name of the stack to be deployed"
}

variable "cluster_name" {
  type        = string
  description = "Name of the ECS Cluster"
}

variable "application_name" {
  type        = string
  description = "Name of the Application"
}

variable "application_port" {
  type        = number
  description = "Port of the Application"
}

variable "instance_type" {
  type        = string
  description = "Type of the instance for application"
}

variable "db_container_name" {
  type        = string
  description = "Name for the ElasticSearch Service"
}

variable "db_docker_image" {
  type        = string
  description = "ElasticSearch Image"
}

variable "db_dns_name" {
  type        = string
  description = "ElasticSearch Host Name"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
}

variable "create_only_elastic" {
  type        = bool
  description = "Only Create ElasticSearch resources"
}
