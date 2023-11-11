region             = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b"]
stack              = "nba-play-db"

cluster_name = "nba-play-db-cluster"

application_name = "nba-play-db-frontend"
application_port = 80
instance_type    = "t4g.micro"

db_container_name = "nba-play-db-es"
db_docker_image   = "public.ecr.aws/elastic/elasticsearch:7.17.11"
db_dns_name       = "elastic-host"

vpc_cidr = "10.0.0.0/16"


# whether to create only ElaticSearch resources or not. Setting "true", will not create ECS resources
create_only_elastic = true