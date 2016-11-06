provider "aws" {
  region = "us-west-2"
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

}

resource "null_resource" "conf" {
  # Copies the myapp.conf file to /etc/myapp.conf
  provisioner "file" {
      source = "conf/myapp.conf"
      destination = "/etc/myapp.conf"
  }
}

resource "aws_ecr_repository" "foo" {
  name = "bar"
}

module "nginx" {
  # this sources from the "stack//service" module
  source          = "github.com/segmentio/stack//service"
  name            = "nginx"
  image           = "foo"
  dns_name        = "vkulov-app"
  port            = 80
  environment     = "${module.stack.environment}"
  cluster         = "${module.stack.cluster}"
  iam_role        = "${module.stack.iam_role}"
  security_groups = "${module.stack.internal_elb}"
  subnet_ids      = "${join(",", module.stack.internal_subnets)}"
  log_bucket      = "${module.stack.log_bucket_id}"
  zone_id         = "${module.stack.zone_id}"
}
