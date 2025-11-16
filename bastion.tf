resource "aws_instance" "eks_jumpserver" {
  ami                         = "ami-0ecb62995f68bb549"
  instance_type               = "t2.micro"
  key_name                    = data.aws_key_pair.jumpserver_key.key_name
  subnet_id                   = data.aws_subnets.prod_blog_subnets_public.ids[0]
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.jumpserver.id]
  iam_instance_profile   = aws_iam_instance_profile.jumpserver.name
  user_data_base64       = filebase64("${path.module}/bastion-setup.sh")

  lifecycle {
    # This instructs Terraform to ignore any future changes to the user_data_base64 attribute after the instance is first created.
    ignore_changes = [
      user_data_base64,
    ]
  }

  tags = {
    Name = "eks-bastion-prod-blogapp"
  }

  depends_on = [aws_security_group.jumpserver]
}


# Security Group for Jump Server
resource "aws_security_group" "jumpserver" {
  name_prefix = "${local.name}-jumpserver-sg"
  vpc_id      = data.aws_vpc.prod_blog.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-jumpserver-sg"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "jumpserver" {
  name = "${local.name}-eks-jumpserver-instance-profile"
  role = aws_iam_role.jumpserver.name
}

# IAM Role for Jump Server
resource "aws_iam_role" "jumpserver" {
  name = "${local.name}-eks-jumpserver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "eks-jumpserver-role"
  }
}

# IAM Policy for EKS Access
resource "aws_iam_policy" "jumpserver_eks_access" {
  name        = "${local.name}-EKSJumpServerAccess"
  description = "Policy for Jump Server to access EKS cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:ListUpdates",
          "eks:ListFargateProfiles",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to jump server role
resource "aws_iam_role_policy_attachment" "jumpserver_eks_access" {
  role       = aws_iam_role.jumpserver.name
  policy_arn = aws_iam_policy.jumpserver_eks_access.arn
}

resource "aws_iam_role_policy_attachment" "jumpserver_ssm" {
  role       = aws_iam_role.jumpserver.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}




