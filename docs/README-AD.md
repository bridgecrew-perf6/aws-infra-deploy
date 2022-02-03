### Active Directory

If you want the terraform script to deploy an AD server, set `ad_server_enabled=true` in your `infra.tfvars` file.

You will need to run `terraform apply ...` after making the update.  

Run `terraform output ad_server_private_ip` to get the AD server IP address.

```
System Settings -> User Authentication
   -> Authentication Type: Active Directory
   -> Security Protocol: LDAPS
   -> Service Location: ${ad_server_private_ip} | Port: 636
   -> Bind Type: Search Bind
   -> User Attribute: sAMAccountName
   -> Base DN: CN=Users,DC=samdom,DC=example,DC=com
   -> Bind DN: cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
   -> Bind Password: 5ambaPwd@
```

Two AD groups and two AD users were created automatically when the enviroment was provisioned:

- `DemoTenantAdmins` group
- `DemoTenantUsers` group
- `ad_user1` in the `DemoTenantUsers` group with password `pass123`
- `ad_admin1` in the `DemoTenantAdmins` group with password `pass123`


### Directory Browser

Sometimes it's useful to browse the AD tree with a graphical interface.  This section describes how to connect with the open source Apache Directory Studio.

- Download and install Apache Director Studio
- Run `$(terraform output ad_server_ssh_command) -L 1636:localhost:636` - this retrieves from the terraform environment the ssh command required to connect to the AD EC2 instance.  The `-L 1636:localhost:636` command tells ssh to bind to port `1636` on your local machine and forward traffic to the port `636` on the AD EC2 instance.  Exiting the ssh session will remove the port binding.
- In Apache Directory Studio, create a new connection:
  - *Connection name:* choose something meaningful
  - *Hostname:* localhost
  - *Port:* 1636
  - *Connection timeout(s):* 30
  - *Encryption method:* No encryption
  - *Provider:* Apache Directory LDAP Client API
  - **Click *Next***
  - *Authentication Method:* Simple Authentication
  - *Bind DN or user:* cn=Administrator,CN=Users,DC=samdom,DC=example,DC=com
  - *Bind password:* 5ambaPwd@
  - **Click *Finish***
