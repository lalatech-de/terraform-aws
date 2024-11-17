data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}


module "ex_vpc" { # Virtual Private Cloud
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name 
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]


  tags = {
    Terraform   = "true"
    Environment = var.environment.name
  }
}

module "blog_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.0"

  name = "blog"

  min_size            = var.asg_min
  max_size            = var.asg_max
  vpc_zone_identifier = module.ex_vpc.public_subnets
  # target_group_arns   = module.blog_alb.target_group_arns
  security_groups     = [module.blog_sg.security_group_id]
  instance_type       = var.instance_type
  image_id            = data.aws_ami.app_ami.id
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.12.0"
  name    = "blog-alb"

  load_balancer_type = "application"

  vpc_id          = module.ex_vpc.vpc_id
  subnets         = module.ex_vpc.public_subnets
  security_groups = [module.blog_sg.security_group_id]

  target_groups = {
    blog-instance = {
      name_prefix = "blog-"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = "i-0f6d38a07d50d080f"
    }
  }

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  vpc_id              = module.ex_vpc.default_vpc_id
  name                = "blog"
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}
