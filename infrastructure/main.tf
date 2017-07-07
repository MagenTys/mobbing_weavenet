provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_ecr_repository" "dockerweavesample_server" {
  name = "dockerweavesample_server"
}

resource "aws_ecr_repository" "dockerweavesample_client" {
  name = "dockerweavesample_client"
}
