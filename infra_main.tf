// Usage: terraform <action> -var-file="etc/infra.tfvars"

terraform {
  required_version = ">= 0.12.21"
  required_providers {
    aws = ">= 2.25.0"
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}

data "aws_availability_zone" "main" {
  name = var.az
}

data "external" "example1" {
 program = [ "python3", "${path.module}/scripts/verify_client_ip.py", "${var.client_cidr_block}", "${var.check_client_ip}" ]
}

data "local_file" "ssh_pub_key" {
    filename = var.ssh_pub_key_path
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_id}-keypair"
  public_key = data.local_file.ssh_pub_key.content
}

/******************* modules ********************/

module "network" {
  source = "./modules/module-network"
  project_id = var.project_id
  user = var.user
  client_cidr_block = var.client_cidr_block
  additional_client_ip_list = var.additional_client_ip_list
  subnet_cidr_block = var.subnet_cidr_block
  vpc_cidr_block = var.vpc_cidr_block
  aws_zone_id = data.aws_availability_zone.main.zone_id
}

module "controller" {
  source = "./modules/module-controller"
  create_eip = var.create_eip_controller
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  client_cidr_block = var.client_cidr_block
  additional_client_ip_list = var.additional_client_ip_list
  subnet_cidr_block = var.subnet_cidr_block
  vpc_cidr_block = var.vpc_cidr_block
  aws_zone_id = data.aws_availability_zone.main.zone_id
  az = var.az
  ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
  ctr_instance_type = var.ctr_instance_type
  key_name = aws_key_pair.main.key_name
  security_group_ids = flatten([ 
    module.network.security_group_allow_all_from_client_ip, 
    module.network.security_group_main_id,
    var.allow_ssh_from_world == true ? [ module.network.security_group_allow_ssh_from_world_id ] : []
  ])
  subnet_id = module.network.subnet_main_id
}

# module "gateway" {
#   source = "./modules/module-gateway"
#   create_eip = var.create_eip_gateway
#   project_id = var.project_id
#   user = var.user
#   ssh_prv_key_path = var.ssh_prv_key_path
#   client_cidr_block = var.client_cidr_block
#   additional_client_ip_list = var.additional_client_ip_list
#   subnet_cidr_block = var.subnet_cidr_block
#   vpc_cidr_block = var.vpc_cidr_block
#   aws_zone_id = data.aws_availability_zone.main.zone_id
#   az = var.az
#   ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
#   gtw_instance_type = var.gtw_instance_type
#   key_name = aws_key_pair.main.key_name
#   security_group_ids = flatten([ 
#     module.network.security_group_allow_all_from_client_ip, 
#     module.network.security_group_main_id,
#     var.allow_ssh_from_world == true ? [ module.network.security_group_allow_ssh_from_world_id ] : []
#   ])
#   subnet_id = module.network.subnet_main_id
# }


module "nfs_server" {
  source = "./modules/module-nfs-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  nfs_ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
  nfs_instance_type = var.nfs_instance_type
  nfs_server_enabled = var.nfs_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [ 
    module.network.security_group_allow_all_from_client_ip, 
    module.network.security_group_main_id
  ]
  subnet_id = module.network.subnet_main_id
}

module "ad_server" {
  source = "./modules/module-ad-server"
  project_id = var.project_id
  user = var.user
  ssh_prv_key_path = var.ssh_prv_key_path
  ad_ec2_ami = var.EC2_CENTOS7_AMIS[var.region]
  ad_instance_type = var.ad_instance_type
  ad_server_enabled = var.ad_server_enabled
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = [
    module.network.security_group_allow_all_from_client_ip, 
    module.network.security_group_main_id
  ]
  subnet_id = module.network.subnet_main_id
}

# module "rdp_server" {
#   source = "./modules/module-rdp-server"
#   project_id = var.project_id
#   user = var.user
#   ssh_prv_key_path = var.ssh_prv_key_path
#   rdp_ec2_ami = var.EC2_WIN_RDP_AMIS[var.region]
#   rdp_instance_type = var.rdp_instance_type
#   rdp_server_enabled = var.rdp_server_enabled && var.rdp_server_operating_system == "WINDOWS"
#   key_name = aws_key_pair.main.key_name
#   vpc_security_group_ids = flatten([ 
#     module.network.security_group_allow_all_from_client_ip, 
#     module.network.security_group_main_id,
#     var.allow_rdp_from_world == true ? [ module.network.security_group_allow_rdp_from_world_id ] : []
#   ])
#   subnet_id = module.network.subnet_main_id
# }

module "rdp_server" {
  source = "./modules/module-rdp-server"
  project_id = var.project_id
  user = var.user
  az = var.az
  ssh_prv_key_path = var.ssh_prv_key_path
  rdp_ec2_ami = var.EC2_LIN_RDP_AMIS[var.region]
  rdp_instance_type = var.rdp_instance_type
  rdp_server_enabled = var.rdp_server_enabled && var.rdp_server_operating_system == "LINUX" 
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([ 
    module.network.security_group_allow_all_from_client_ip, 
    module.network.security_group_main_id,
    var.allow_rdp_from_world == true ? [ module.network.security_group_allow_rdp_from_world_id ] : []
  ])
  subnet_id = module.network.subnet_main_id
}

module "rdp_server_linux" {
  source = "./modules/module-rdp-server-linux"
  project_id = var.project_id
  user = var.user
  az = var.az
  ssh_prv_key_path = var.ssh_prv_key_path
  rdp_ec2_ami = var.EC2_LIN_RDP_AMIS[var.region]
  rdp_instance_type = var.rdp_instance_type
  rdp_server_enabled = var.rdp_server_enabled && var.rdp_server_operating_system == "LINUX" 
  key_name = aws_key_pair.main.key_name
  vpc_security_group_ids = flatten([ 
    module.network.security_group_allow_all_from_client_ip, 
    module.network.security_group_main_id,
    var.allow_rdp_from_world == true ? [ module.network.security_group_allow_rdp_from_world_id ] : []
  ])
  subnet_id = module.network.subnet_main_id
}