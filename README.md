# dev_ops_lego

This repo is tfenv enabled you can install this with the following instructions [here](https://github.com/tfutils/tfenv) otherwise it requires 1.1.9 which can be downloaded [here](https://www.terraform.io/downloads)


## Running the script
```bash
cd environment

# if using tfenv
tfenv install

terraform init
terraform apply --var-file prod.tfvars.json
```

## Destroying the environment
```bash
cd environment

#if using tfenv
tfenv install

terraform destroy --var-file prod.tfvars.json
```

The script will output the url of the loadbalancer once the apply has complete, you should be able to navigate to this after the loadbalancer has finished provisioning the dns.

The hello world application that is installed as part of the script will show 
```json
{
  hostname: "{hostname}",
  uptime: {uptime},
  podname: "{podname}"
}
```
From my experimenting it looks like the loadbalancer uses sticky sessions, so you will most likely always hit the same pod on each request. By using incognito you can usually hit another pod


## Folder Structure
### environment

This includes all the files that are actually run by terraform

- `eks.tf`  
  this creates the the cluster
- `hello-world.tf`  
  this creates the application inside the kubernetes cluster once provisioned
- `providers.tf`  
  this is where all the providers are initialized
- `security_groups.tf`  
  creates all the security groups that require both information from the network and the cluster, this stop having to pass other information about the network to eks.tf
- `variables.tf`  
  stores all the terraform models that are generated from the `tfvars.json`
- `version.tf`  
  stores all the terraform specific information, such as the backend storage, the version fixing for all the external providers and the required version for the script to run
- `vpc.tf`  
  calls the module that creates the vpc network and all the underlying infrastructure