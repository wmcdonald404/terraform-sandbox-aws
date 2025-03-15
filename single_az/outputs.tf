output "instance_ips" {
  value = ["${aws_instance.public_bastions.*.public_ip}"]
}

output "instance_ids" {
  value = ["${aws_instance.public_bastions.*.id}"]
}