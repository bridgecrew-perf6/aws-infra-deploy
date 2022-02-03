#!/bin/bash

terraform destroy -var-file=etc/infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true
