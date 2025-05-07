resource "local_file" "encrypted_config" {
  content = templatefile("${path.module}/encryption-provider-config.tpl", {
    encryption_secret_key = var.encryption_secret_key
  })
  filename = "${path.module}/encryption-provider-config.yaml"
}

resource "aws_instance" "rke2_node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = aws_subnet.rancher_subnet.id
  vpc_security_group_ids      = [aws_security_group.rancher_sg_allowall.id]
  associate_public_ip_address = var.preserve_eip ? false : true

  root_block_device {
    volume_size           = var.root_volume_size
    delete_on_termination = true
    volume_type           = "gp2"
  }

  tags = {
    Name = "${var.prefix}-rke2-node"
  }
}

# Allocate an Elastic IP for the instance in case the preserve_eip is set
resource "aws_eip" "static_ip" {
  count  = var.preserve_eip ? 1 : 0
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-static-ip"
  }
  lifecycle {
    prevent_destroy = true
  }
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "eip_association" {
  count         = var.preserve_eip ? 1 : 0
  instance_id   = aws_instance.rke2_node.id
  allocation_id = aws_eip.static_ip[0].id
}

# Determine the host IP (with conditional logic)
locals {
  rke2_host_ip = var.preserve_eip ? aws_eip.static_ip[0].public_ip : aws_instance.rke2_node.public_ip
}

# Use a null_resource to handle SSH-based provisioning
resource "null_resource" "provision_rke2" {
  depends_on = [aws_instance.rke2_node]

  provisioner "file" {
    source      = "install_rancher.sh"
    destination = "/home/ubuntu/install_rancher.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_path}")
      host        = local.rke2_host_ip
    }
  }

  provisioner "file" {
    source      = local_file.encrypted_config.filename
    destination = "/home/ubuntu/encryption-provider-config.yaml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_path}")
      host        = local.rke2_host_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install_rancher.sh",
      "sudo /home/ubuntu/install_rancher.sh ${var.rke2_version} ${var.cert_manager_version}"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${var.private_key_path}")
      host        = local.rke2_host_ip
    }
  }
}

# Output the public IP of the instance
output "public_ip" {
  value = local.rke2_host_ip
}

# Output the vpc and subnet details used in the automation
output "network_info" {
  value = {
    subnet_id = aws_subnet.rancher_subnet.id
    vpc_id    = aws_vpc.rancher_vpc.id
  }
}


# Update the cattle config file and the vpc, subnet details in the configuration files
resource "null_resource" "update_yaml" {
  provisioner "local-exec" {
    command = <<EOT
      if [ -f "${var.input_cluster_config}"]; then
        yq e '.machineconfig.data.subnetId = "${aws_subnet.rancher_subnet.id}" | .machineconfig.data.vpcId = "${aws_vpc.rancher_vpc.id}"' \
          -i "${var.input_cluster_config}"
      else
        echo "Warning: inputClusterConfig.yaml not found. Skipping update."
      fi
      if [ -f "${var.cattle_config}" ]; then
        yq e '.rancher.host = "rancher.${local.rke2_host_ip}.sslip.io"' \
          -i "${var.cattle_config}"
      else
	echo "Warning: ${var.cattle_config} not found. Skipping update."
      fi
    EOT
  }

  depends_on = [
    aws_subnet.rancher_subnet,
    aws_vpc.rancher_vpc,
    aws_instance.rke2_node
  ]
}
