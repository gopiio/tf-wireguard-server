output "wireguard_server_name" {
  description = "Wireguard server name"
  value       = local.wg_server_name
}

output "wireguard_server_ip" {
  description = "Wireguard server IP-address"
  value       = aws_eip.main.public_ip
}

output "wireguard_server_port" {
  description = "Wireguard server port"
  value       = var.wg_listen_port
}

output "wireguard_server_endpoint" {
  description = "Wireguard server endpoint"
  value       = format("%s:%s", aws_eip.main.public_ip, var.wg_listen_port)
}

output "launch_template_arn" {
  description = "EC2 launch template ARN"
  value       = aws_launch_template.main.arn
}

output "launch_template_id" {
  description = "EC2 launch template ID"
  value       = aws_launch_template.main.id
}

output "autoscaling_group_arn" {
  description = "EC2 autoscaling group ARN"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "EC2 autoscaling group name"
  value       = aws_autoscaling_group.main.name
}

output "sqs_queue_arn" {
  description = "SQS queue for S3 notifications ARN"
  value       = aws_sqs_queue.main.arn
}

output "sqs_queue_id" {
  description = "SQS queue for S3 notifications ID"
  value       = aws_sqs_queue.main.id
}

output "sqs_queue_dead_letter_arn" {
  description = "SQS dead letter queue for S3 notifications ARN"
  value       = aws_sqs_queue.main_dead_letter.arn
}

output "sqs_queue_dead_letter_id" {
  description = "SQS dead letter queue for S3 notifications ID"
  value       = aws_sqs_queue.main_dead_letter.id
}

output "s3_bucket_arn" {
  description = "Wireguard configuration S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_name" {
  description = "Wireguard configuration S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "iam_role_arn" {
  description = "ARN of IAM role to access S3 bucket"
  value       = aws_iam_role.main.arn
}

output "iam_role_name" {
  description = "Name of IAM role to access S3 bucket"
  value       = aws_iam_role.main.name
}

output "iam_instance_profile_arn" {
  description = "ARN of IAM instance profile to access S3 bucket"
  value       = aws_iam_instance_profile.main.arn
}

output "iam_instance_profile_id" {
  description = "ID of IAM instance profile to access S3 bucket"
  value       = aws_iam_instance_profile.main.id
}
