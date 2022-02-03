
resource "local_file" "ca-cert" {
  filename = "${path.module}/generated/ca-cert.pem"
  content =  var.ca_cert
}

resource "local_file" "ca-key" {
  filename = "${path.module}/generated/ca-key.pem"
  content =  var.ca_key
}


//////////////////// Utility scripts  /////////////////////

/// instance start/stop/status

locals {
  instance_ids = "${module.nfs_server.instance_id != null ? module.nfs_server.instance_id : ""} ${module.ad_server.instance_id != null ? module.ad_server.instance_id : ""} ${module.rdp_server.instance_id != null ? module.rdp_server.instance_id : ""} ${module.rdp_server_linux.instance_id != null ? module.rdp_server_linux.instance_id : ""} ${module.controller.id} ${join(" ", aws_instance.workers.*.id)}"
}

resource "local_file" "cli_stop_ec2_instances" {
  filename = "${path.module}/generated/cli_stop_ec2_instances.sh"
  content =  <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"

    SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o ConnectionAttempts=1 -q"
    CMD='nohup sudo halt -n </dev/null &'

    echo "Sending 'sudo halt -n' to all hosts"

    for HOST in $${WRKR_PUB_IPS[@]};
    do
      ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$HOST "$CMD" || true
    done

    ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$GATW_PUB_IP "$CMD" || true
    ssh $SSH_OPTS -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$CMD" || true

    echo "Sleeping a few minutes, allowing halt to complete"
    sleep 120

    echo "Stopping instances"
    aws --region ${var.region} --profile ${var.profile} ec2 stop-instances --instance-ids ${local.instance_ids} 
  EOF
}

resource "local_file" "cli_start_ec2_instances" {
  filename = "${path.module}/generated/cli_start_ec2_instances.sh"
  content = <<-EOF
    #!/bin/bash
    aws --region ${var.region} --profile ${var.profile} ec2 start-instances --instance-ids ${local.instance_ids} 

    echo "*******************************************************************************"
    echo "IMPORTANT: You need to run the following command to update changed IP addresses"
    echo "           ./bin/terraform_apply.sh"
    echo "*******************************************************************************"
  EOF
}

resource "local_file" "cli_running_ec2_instances" {
  filename = "${path.module}/generated/cli_running_ec2_instances.sh"
  content = <<-EOF
    echo Running:  $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=running --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Starting: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=pending --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopping: $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=stopping --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
    echo Stopped:  $(aws --region ${var.region} --profile ${var.profile} ec2 describe-instance-status --instance-ids ${local.instance_ids} --filter Name=instance-state-name,Values=stopped --include-all-instances --output text | grep '^INSTANCESTATE' | wc -l)
  EOF  
}

resource "local_file" "ssh_controller_port_forwards" {
  filename = "${path.module}/generated/ssh_controller_port_forwards.sh"
  content = <<-EOF
    #!/bin/bash

    source "${path.module}/scripts/variables.sh"

    if [[ -e "${path.module}/etc/port_forwards.sh" ]]
    then
      PORT_FORWARDS=$(cat "${path.module}/etc/port_forwards.sh")
    else
      echo ./etc/port_forwards.sh file not found please create it and add your rules, e.g.
      echo cp ./etc/port_forwards.sh ./etc/port_forwards.sh
      exit 1
    fi
    echo Creating port forwards from "${path.module}/etc/port_forwards.sh"

    set -x
    ssh -o StrictHostKeyChecking=no \
      -i "${var.ssh_prv_key_path}" \
      -N \
      centos@$CTRL_PUB_IP \
      $PORT_FORWARDS \
      "$@"
  EOF
}

resource "local_file" "ssh_controller" {
  filename = "${path.module}/generated/ssh_controller.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
  EOF
}

resource "local_file" "ssh_gateway" {
  filename = "${path.module}/generated/ssh_gateway.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
  EOF
}

resource "local_file" "ssh_worker" {
  count = var.worker_count

  filename = "${path.module}/generated/ssh_worker_${count.index + 1}.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$${WRKR_PUB_IPS[${count.index}]} "$@"
  EOF
}

resource "local_file" "ssh_workers" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_worker_all.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     for HOST in $${WRKR_PUB_IPS[@]}; 
     do
      ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$HOST "$@"
     done
  EOF
}

resource "local_file" "ssh_all" {
  count = var.worker_count
  filename = "${path.module}/generated/ssh_all.sh"
  content = <<-EOF
     #!/bin/bash
     source "${path.module}/scripts/variables.sh"
     if [[ $# -lt 1 ]]
     then
        echo "You must provide at least one command, e.g."
        echo "./generated/ssh_worker_all.sh CMD1 CMD2 CMDn"
        exit 1
     fi

     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$CTRL_PUB_IP "$@"
     ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$GATW_PUB_IP "$@"
     for HOST in $${WRKR_PUB_IPS[@]};
     do
        ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" centos@$HOST "$@"
     done
  EOF
}

resource "local_file" "rdp_windows_credentials" {
  filename = "${path.module}/generated/rdp_credentials.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "WINDOWS" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"

    if grep -q 'OPENSSH' "${var.ssh_prv_key_path}"
    then
      echo "***** ERROR ******"
      echo "Found OPENSSH key but need RSA key at ${var.ssh_prv_key_path}"
      echo "You can convert with:"
      echo "$ ssh-keygen -p -N '' -m pem -f '${var.ssh_prv_key_path}'"
      echo "******************"
      exit 1
    fi

    echo 
    echo ==== RDP Credentials ====
    echo 
    echo IP Addr:  ${module.rdp_server.public_ip}
    echo URL:      "rdp://full%20address=s:${module.rdp_server.public_ip}:3389&username=s:Administrator"
    echo Username: Administrator
    echo -n "Password: "
    aws --region ${var.region} \
        --profile ${var.profile} \
        ec2 get-password-data \
        "--instance-id=${module.rdp_server.instance_id}" \
        --query 'PasswordData' | sed 's/\"\\r\\n//' | sed 's/\\r\\n\"//' | base64 -D | openssl rsautl -inkey "${var.ssh_prv_key_path}" -decrypt
    echo
    echo
  EOF
}

resource "local_file" "rdp_linux_credentials" {
  filename = "${path.module}/generated/rdp_credentials.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    echo 
    echo ==== RDP Credentials ====
    echo 
    echo IP Addr:  "https://$RDP_PUB_IP"
    echo Username: ubuntu
    echo Password: $RDP_INSTANCE_ID
    echo
  EOF
}

resource "local_file" "ssh_rdp_linux" {
  filename = "${path.module}/generated/ssh_rdp_linux_server.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    ssh -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP "$@"    
  EOF
}

resource "local_file" "sftp_rdp_linux" {
  filename = "${path.module}/generated/sftp_rdp_linux_server.sh"
  count = var.rdp_server_enabled == true && var.rdp_server_operating_system == "LINUX" ? 1 : 0
  content = <<-EOF
    #!/bin/bash
    source "${path.module}/scripts/variables.sh"
    sftp -o StrictHostKeyChecking=no -i "${var.ssh_prv_key_path}" ubuntu@$RDP_PUB_IP    
  EOF
}

resource "local_file" "whatismyip" {
  filename = "${path.module}/generated/whatismyip.sh"

  content = <<-EOF
     #!/bin/bash
     echo $(curl -s http://ifconfig.me/ip)/32
  EOF
}