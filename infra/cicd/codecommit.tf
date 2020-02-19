#--------------------------------------------------------------
# CodeCommit repo
#--------------------------------------------------------------
resource "aws_codecommit_repository" "app_repo" {
  repository_name = var.app_name
}