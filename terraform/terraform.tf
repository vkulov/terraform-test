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

  ecs_min_size = "1"
  ecs_max_size = "1"
  ecs_desired_capacity = "1"
}

#resource "null_resource" "conf" {
  # Copies the myapp.conf file to /etc/myapp.conf
#  provisioner "file" {
#      source = "conf/myapp.conf"
#      destination = "/etc/myapp.conf"
#  }
#}

resource "aws_ecr_repository" "main" {
  name = "vkulov"
}

module "nginx" {
  # this sources from the "stack//service" module
  source          = "github.com/segmentio/stack//web-service"
  name            = "nginx"
  image           = "foo"

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





resource "aws_codedeploy_app" "main" {
    name = "vkulov"
}

resource "aws_iam_role_policy" "deploy_policy" {
    name = "vkulov_policy"
    role = "${aws_iam_role.vkulov_deploy_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "tag:GetTags",
                "tag:GetResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "vkulov_deploy_role" {
    name = "vkulov_deploy_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_deployment_group" "main" {
    app_name = "${aws_codedeploy_app.main.name}"
    deployment_group_name = "vkulov"
    service_role_arn = "${aws_iam_role.vkulov_deploy_role.arn}"

    # autoscaling_groups = ["vkulov-app"]

    ec2_tag_filter {
        key = "aws:autoscaling:groupName"
        type = "KEY_AND_VALUE"
        value = "vkulov-app"
    }

    #trigger_configuration {
    #    trigger_events = ["DeploymentFailure"]
    #    trigger_name = "foo-trigger"
    #    trigger_target_arn = "foo-topic-arn"
    #}
}