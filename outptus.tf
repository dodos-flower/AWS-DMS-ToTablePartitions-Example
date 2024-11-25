output "dms_instance_arn" {
  value = aws_dms_replication_instance.dms_instance.replication_instance_arn
}

output "dms_task_status" {
  value = aws_dms_task.dms_task.status
}
