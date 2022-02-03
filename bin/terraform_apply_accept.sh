#!/bin/bash

terraform apply -var-file=etc/infra.tfvars \
   -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" -auto-approve=true

terraform output -json > generated/output.json

