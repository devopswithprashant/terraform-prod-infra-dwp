data "aws_region" "current" {}

data "aws_vpc" "prod_blog" {
  tags = {
    Name = "myVPC"
    Type = "prod"
  }
}

data "aws_subnets" "prod_blog_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.nonprod_blog.id]
  }

  tags = {
    Type = "Private"
  }
}

data "aws_subnets" "prod_blog_subnets_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.nonprod_blog.id]
  }

  tags = {
    Type = "Public"
  }
}


data "aws_key_pair" "jumpserver_key" {
  key_name = "mywebKey"
}

# Ubuntu AMI data source
# data "aws_ami" "ubuntu" {
#   most_recent = true
#   owners      = ["099720109477"] # Canonical
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-*-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }
