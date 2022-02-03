#
# Select an appropriate region and availability zone
#

profile            = "default"
region             = "eu-west-2"
az                 = "eu-west-2a"

#
# Set this to something meaningful.  it is used as a tag in aws 
#

project_id         = "xxx"
user               = "xxx"

#
# Before setting the vpc cidr block, manually verify the vpc cidr doesn't already exist in your region
#

vpc_cidr_block     = "10.11.0.0/16"
subnet_cidr_block  = "10.11.0.0/24"

# This project requirs a client cidr block to be set to allow access to the aws vpc from your client machine
# Most users will set the client cidr block automatically using the terraform CLI, e.g.
#
# `terraform apply ... -var="client_cidr_block=$(curl -s http://ifconfig.me/ip)/32" ...`
#
# The above approach retrieves the internet IP of your gateway connection to the internet.
# The benefit of using the CLI is that if you change networks frequently (e.g. mobile users), you can simply
# run the `terraform apply ...` command again and it will update the AWS network ACL with your new address.
# If your client is always on the same network and you don't wish to set your client cidr block with the CLI,
# you can set this address below.

# client_cidr_block  = "x.x.x.x/32"


# Set the check_client_ip to true to check if the current client_ip is inside the client_cidr_block
# If the client_ip isn't inside the client_cidr_block, you won't be able to connect to the VPN from your client machine.

check_client_ip  = "true"

# If you want to allow other clients to have full network access to this environment, add them here.
# These IPs need a suffix such as /32 for specific IP address

additional_client_ip_list = []  # E.g. [ "1.1.1.1/24","2.2.2.2/32" ]

# specify how many CDP workers you want
worker_count = 1

# you may need to change the instance types if the ones
# listed below are not available in your region

#gtw_instance_type  = "m4.xlarge" # Paris: "m5.4xlarge"
ctr_instance_type  = "m4.xlarge" # Paris: "m5.4xlarge"
wkr_instance_type  = "m4.2xlarge" # Paris: "m5.4xlarge"
nfs_instance_type  = "t2.small"
ad_instance_type   = "t2.small"

# Whether to create an EIP for the controller - you may wish to disable this
# if you are short on EIPs. If you don't create the EIP, you probably need to 
# enable the RDP server.

create_eip_controller = false

# Whether to create an EIP for the gateway - you may wish to disable this
# if you are short on EIPs. If you don't create the EIP, you probably need to 
# enable the RDP server.

create_eip_gateway = false

# the path to your ssh private key on your local machine
# use double \\ for windows paths

ssh_prv_key_path   = "keys/id_rsa" 
ssh_pub_key_path   = "keys/id_rsa.pub" 

#selinux_disabled     = true

# set to true to enable a nfs server
#gateway_server_enabled = false
nfs_server_enabled = false

# set to true to create an Active Directory server

ad_server_enabled = true

# windows rdp server

rdp_server_enabled = false

# set to "WINDOWS" or "LINUX"

rdp_server_operating_system = "LINUX"

# If you would like to allow ssh or rdp from any source, set the following variables

allow_ssh_from_world = false
allow_rdp_from_world = false

# CA Key for signing the controller certificate - use this or replace with your own

ca_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAmuBggPR0hBnydZfXPnHAPA+sSG9ixA+7nfduGrfkLNuGRl7r
NxlU0ilFcXriBEpv39dCNVFtUPJJ/ZREo1jRpLPrjrxP6vCgsYMMNhy9qP4Jk593
wE0PkAnsUYol3DZT3s8wDLsmSRE0ylEg4f1D1DIjXSnr6h6/O9OgajFEUna9OkGf
kJDr9/hY4iQwm5ccerdj0jDiPkWRI2JRQe1/2/UvahrhM4dt+ijeevsZ05AuCBbv
5Mpb22jdJGAVRfkbQtOBM9JLIOjG8mykbZg5h3kYm/0qU0RjPd9P444zGhkyKYfT
K0MRFoQwf4ghzzOhocovFt5abcLNsuYs1tYNUwIDAQABAoIBAGiWd3T+ICUJZKu2
s1tu87Nbnit4VMk0Gq3tZoRShJsqT/37oXoe+CHITyX4JuNg5TXTJtncuCa+x+qf
ks6Ab2p7Oeq1Dn8IqmvVpIxyUj3p98uiF/tbztOlb9oMoc6ZPYAsiDVAuPUE0pKB
wOP75S9KAImsgq0iwF+FZUHxLUNF8UfCtEGrWd7nY1MNwF5vZuu5kjT9u3GvAt+s
7guMmNuO/SRwA/OhfTFRtwXUk8o+cJDBnDkmzj+U3dX/Z6eGYS2Jhi+Jo/z4+4LQ
vkMB9Xtgtq9H3q4jbLjhc3mMCf55PLLLHkH5v3Bd3BezeLwuFYm2JOIK9WNuhQQ+
xEZ4omkCgYEAxVS/6m837zKWfhnU9vbMs6rRniLgICn6mNsdPsI9ApP6o4Jk7dTu
XbH6+IxLR+0ipTN2dOcj7RYNnVT6rgb5SosEMrz+UDKOgPeTdmOKhi5JTPp9v2Mt
AhmdtWpf98jyu6HeHL2nTRyiMLRYE/2f7BghyJ9ZRMn/RpxeEXjA+V8CgYEAyOxT
mZsfe0ktnsXIADuFkrOzmUfSR6CCfzATJ5ASqOf7VEG7fWeUGgMtgjZG28TySxNC
YUfSwZb0Dxs3cUhM5l6WU3Ym+7VadiFe93iBWdgwESLczpjfpE7qSTDoShlUWYDv
zsBBgOBfNKAIaTbRB/jqriJrtjBq7O3wIuFLzI0CgYAHnifyguyj3U4V/CVOi2SH
oxaIhkwksbos4HiWjaURTmkkmsoOrGOvVkmcAr59PlhSDFSMWsf2RR2tbzRmN3q0
N/2nf8hJjEoYDHay4VDdsTe/MwRbuRZpuFdwQ3UE+cr1F2Cdt2yX+3z/aFbmHqpn
0N6tAgnOMAYc0biH8CNy/QKBgQCYgUizPtsWaOUHrnewNX2dbGjV333sgBiNEaB4
VxLSwcIyofH9rbDsTZ0tSKVgCo0eDvBDhpCiAEIfdTkP8yDrer//eZ79TxnqsEm0
7PLBjyZs21leNwsJXBzYkRa/p5oulX9wHt2ZRLT+7Ll1ovXmZzk6E0ZOc1G1pKSw
1PEDwQKBgCY+zLSyWs/M3oI9y9aMfOuQFHgRZxDcSG7ce2xGUAwsUKJwtq4XylQZ
QkABF4fWIeEs0h0tOt+yowF1PU7Q4AH1MKQZCoqKP1Y62T/zGRr59huDZlN+Z3tf
OIotPP8nCOs8Sqq76VHaFxLLIrkCowq+wjtLzNgRRGbkDwohd//l
-----END RSA PRIVATE KEY-----
EOF

# CA Cert corresponding to the CA Key - use this or replace with your own

ca_cert = <<EOF
-----BEGIN CERTIFICATE-----
MIIDSzCCAjOgAwIBAgIIPkySS+2b3eIwDQYJKoZIhvcNAQELBQAwIDEeMBwGA1UE
AxMVbWluaWNhIHJvb3QgY2EgM2U0YzkyMCAXDTIwMDIyOTE4MTk1MFoYDzIxMjAw
MjI5MTgxOTUwWjAgMR4wHAYDVQQDExVtaW5pY2Egcm9vdCBjYSAzZTRjOTIwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCa4GCA9HSEGfJ1l9c+ccA8D6xI
b2LED7ud924at+Qs24ZGXus3GVTSKUVxeuIESm/f10I1UW1Q8kn9lESjWNGks+uO
vE/q8KCxgww2HL2o/gmTn3fATQ+QCexRiiXcNlPezzAMuyZJETTKUSDh/UPUMiNd
KevqHr8706BqMURSdr06QZ+QkOv3+FjiJDCblxx6t2PSMOI+RZEjYlFB7X/b9S9q
GuEzh236KN56+xnTkC4IFu/kylvbaN0kYBVF+RtC04Ez0ksg6MbybKRtmDmHeRib
/SpTRGM930/jjjMaGTIph9MrQxEWhDB/iCHPM6Ghyi8W3lptws2y5izW1g1TAgMB
AAGjgYYwgYMwDgYDVR0PAQH/BAQDAgKEMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
BgEFBQcDAjASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBQT2Q46hkQnjZ7G
BBgMrpZIv0FemjAfBgNVHSMEGDAWgBQT2Q46hkQnjZ7GBBgMrpZIv0FemjANBgkq
hkiG9w0BAQsFAAOCAQEATB+YL20s8OLBPyl5OKwdNDqaMpAK0voZW2TVS0Qo6Igk
72mq0kpdHypdJjYhMK2e49/NZD3s2KCJWLzV7WVZ2LHy0MXzxZKIzQYbzg/GMbn1
zYp3aj4TRiJaoPaokupq07/qYDUyg2Raq51ffoHSH6bmQG+6RplRmLU2HCuKYXjZ
0AeuGEEanqV0jlxw3ngcGF+sPj+aXnmMHQJ1V/8E5d2kcbbIFfxNLlkhE2fgkBoG
cip9mzyHK6hoKgRLNuyadurvI6sJ53lyBapCQkYk2TvCrHNKh4UUXIPKYeIpEb7a
mdzJvUDlumspdeiX1InWOc15LrZndFcoyN0PIL+fLg==
-----END CERTIFICATE-----
EOF
