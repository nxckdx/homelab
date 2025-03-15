## Requirements
- Packer installed
- Running Proxmox Cluster
- Check all Values in ```ubuntu-24.04.pkr.hcl```
- .pkvars.hcl (for example ```variables.pkrvar.hcl```) file with the following values (strings):
    - proxmox_api_url
    - proxmox_api_token_id
    - proxmox_api_token_secret

## Validate
    packer validate -var-file=./variables.pkrvars.hcl ubuntu-24.04.pkr.hcl

## Run
    packer build -var-file=./variables.pkrvars.hcl ubuntu-24.04.pkr.hcl