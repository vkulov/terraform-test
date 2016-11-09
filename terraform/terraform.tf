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

  port            = 80
  ssl_certificate_id = "arn:aws:acm:us-west-2:113389272869:certificate/11bb3b1d-9b27-4c32-a3d7-01fef32eb071"

  environment     = "${module.stack.environment}"
  cluster         = "${module.stack.cluster}"
  iam_role        = "${module.stack.iam_role}"
  security_groups = "${module.stack.external_elb}"
  subnet_ids      = "${join(",", module.stack.external_subnets)}"
  log_bucket      = "${module.stack.log_bucket_id}"
  internal_zone_id = "${module.stack.zone_id}"
  external_zone_id = "${module.domain.zone_id}"

  memory           = 128
  desired_count   = 1

  env_vars = <<EOF
[
  { "name": "AWS_REGION",            "value": "${module.stack.region}"        },
  { "name": "AWS_ACCESS_KEY_ID",     "value": "${module.ses_user.access_key}" },
  { "name": "AWS_SECRET_ACCESS_KEY", "value": "${module.ses_user.secret_key}" }
]
EOF
}



module "php" {
  source         = "github.com/segmentio/stack//service"
  name           = "php"
  image          = "vkulov/backend"
  port           = 9000
  container_port = 9000
  dns_name       = "php"

  memory          = 256
  protocol        = "TCP"
  healthcheck     = ""
  desired_count   = 1

  environment     = "${module.stack.environment}"
  cluster         = "${module.stack.cluster}"
  zone_id         = "${module.stack.zone_id}"
  iam_role        = "${module.stack.iam_role}"
  security_groups = "${module.stack.internal_elb}"
  subnet_ids      = "${join(",", module.stack.internal_subnets)}"
  log_bucket      = "${module.stack.log_bucket_id}"
}


module "ses_user" {
  source = "github.com/segmentio/stack//iam-user"
  name   = "ses-user"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ses:*"],
      "Resource":"*"
    }
  ]
}
EOF
}

resource "aws_route53_record" "main" {
  zone_id = "${module.domain.zone_id}"
  name    = "${module.domain.name}"
  type    = "A"

  alias {
    name                   = "${module.nginx.dns}"
    zone_id                = "${module.nginx.zone_id}"
    evaluate_target_health = false
  }
}

output "bastion_ip" {
  value = "${module.stack.bastion_ip}"
}
