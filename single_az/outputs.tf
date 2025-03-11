output "instance_ips" {
  value = ["${aws_instance.public_bastions.*.public_ip}"]
}