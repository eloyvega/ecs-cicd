output "repo_url" {
  value = aws_codecommit_repository.app_repo.clone_url_http
}