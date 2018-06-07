module "vpc" {
  source    = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
  name      = "${var.name}"
  namespace = "${var.namespace}"
  stage     = "${var.stage}"
}

module "dynamic_subnets" {
  source             = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  name               = "${var.name}"
  namespace          = "${var.namespace}"
  stage              = "${var.stage}"
  region             = "${var.region}"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]                                        # TODO: generate from region
  vpc_id             = "${module.vpc.vpc_id}"
  igw_id             = "${module.vpc.igw_id}"
  cidr_block         = "10.0.0.0/16"
}
