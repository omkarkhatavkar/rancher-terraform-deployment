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

  subnet_id              = aws_subnet.rancher_subnet.id
  vpc_security_group_ids = [aws_security_group.rancher_sg_allowall.id]

  root_block_device {
    volume_size           = var.root_volume_size
    delete_on_termination = true
    volume_type           = "gp2"
  }

  tags = {
    Name = "${var.prefix}-rke2-node"
  }
}

# Allocate an Elastic IP for the instance
resource "aws_eip" "static_ip" {
  domain = "vpc"

  tags = {
    Name = "${var.prefix}-static-ip"
  }
}

# Associate the Elastic IP with the EC2 instance
resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.rke2_node.id
  allocation_id = aws_eip.static_ip.id
}

# Use a null_resource to handle SSH-based provisioning
resource "null_resource" "provision_rke2" {
  depends_on = [aws_instance.rke2_node, aws_eip_association.eip_association]

  provisioner "file" {
    source      = "install_rancher.sh"
    destination = "/home/ubuntu/install_rancher.sh"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/${var.key_name}.pem")
      host        = aws_eip.static_ip.public_ip
    }
  }

  provisioner "file" {
    source      = local_file.encrypted_config.filename
    destination = "/home/ubuntu/encryption-provider-config.yaml"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/${var.key_name}.pem")
      host        = aws_eip.static_ip.public_ip
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
      private_key = file("~/${var.key_name}.pem")
      host        = aws_eip.static_ip.public_ip
    }
  }
}

# Output the public IP of the instance
output "static_public_ipv4" {
  value = aws_eip.static_ip.public_ip
}

