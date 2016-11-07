provider "aws" {
  region = "us-west-2"
}


module "domain" {
  source = "github.com/segmentio/stack//dns"
  name   = "vkulov-app.dev"
}

module "stack" {
  source      = "github.com/segmentio/stack"
  environment = "prod"
  key_name    = "vesko"
  name        = "vkulov-app"
  region      = "us-west-2"

  bastion_instance_type = "t2.micro"

  ecs_instance_type = "t2.micro"
  ecs_instance_ebs_optimized = "false"

  ecs_min_size = "1"
  ecs_max_size = "1"
  ecs_desired_capacity = "1"
}

module "nginx" {
  # this sources from the "stack//service" module
  source          = "github.com/segmentio/stack//web-service"
  name            = "nginx"
  image           = "vkulov/frontend"

  # dns_name        = "vkulov-app"

  port            = 80
  environment     = "${module.stack.environment}"
  cluster         = "${module.stack.cluster}"
  iam_role        = "${module.stack.iam_role}"
  security_groups = "${module.stack.internal_elb}"
  subnet_ids      = "${join(",", module.stack.internal_subnets)}"
  log_bucket      = "${module.stack.log_bucket_id}"

  internal_zone_id = "${module.stack.zone_id}"
  external_zone_id = "${module.domain.zone_id}"
}




