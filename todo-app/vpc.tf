# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC with public and private subnets, internet and NAT gateways, route tables, and security groups
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# Create a load balancer in the public subnets
module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.5.0"

  name = "my-elb"

  subnets         = module.vpc.public_subnets
  security_groups = [module.vpc.default_security_group_id]

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# Create an EC2 instance for web server in the public subnets
module "web_server" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.2.0"

  name = "web-server"
  count = 3 # use count instead of instance_count

  ami                         = "ami-0c2b8ca1dad447f8a"
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  associate_public_ip_address = true

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# Create an EC2 instance for application in the private subnets
module "application" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.2.0"

  name = "application"
  count = 3 # use count instead of instance_count

  ami                         = "ami-0c2b8ca1dad447f8a"
  instance_type               = "t2.micro"
  key_name                    = "my-key"
  associate_public_ip_address = false

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# Create an RDS instance for database in the private subnets
module "database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.4.0"

  identifier = "my-database"
  count = 3 # use count instead of instance_count

  engine            = "mysql"
  engine_version    = "8.0.23"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  storage_encrypted = false

  name     = "mydb"
  username = "user"
  password = "pass"
  port     = "3306"

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_ids              = module.vpc.private_subnets

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}