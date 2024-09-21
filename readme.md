# DevOps Exercise


## Introduction 
This Repo includes TF code to provision AWS secure cloud infrastructure with Amazon Network Firewall (ANF).

---
## Running project
the project was run on an AWS burner account created for this case.

in order to run the terraform code you need to create an `init.sh` file and populate the


```bash
cp init.sh.example init.sh
```

and populate the init.sh file. 

This terraform project will also provision FluxCD, to enable GitOps, an ssh key is needed to be linked with a github respository as deploy keys, and set in the `TF_VAR_github_token`, `TF_VAR_private_key_pem` variables to connect the repository


after populating the file, export the file as environment variables.
```bash
source init.sh
```

to confirm if the account is connected successfully run

```bash
aws sts get-caller-identity
```

initialize terraform 

```bash
terraform init
```
run the plan
```bash
terraform plan
```
apply 

```bash
terraform apply
```

## Architecture 

The cloud infrastructure provisioned has 4 subnet types

1. DMZ (Firewall dedicated subnet)
2. Public (Subnet for internet-reachable hosts)
3. Private (Subnet for outbound-only internet connections )
4. Isolated (Subnet for hosts that don't need internet reachability)

All traffic, outbound and inbound, goes through ANF. Since we are using a network firewall, achieving network symmetry in this case is mandatory in order for traffic to flow correctly in the system.





in the figure below it shows a high-level design of the cloud infra this terraform project provisions



![image](./docs/infra.png)

![Alt text](./docs/Infra.png?raw=true "Infra Diagram")


## Notes on the project

1. This terraform project is not intended for production or acutal use in real-life scenarios. The project is not modulerized and reuseable

2. The project does not take into-consideration multi availability zones (AZs). Ideally in production workload, we would provision our infra on multiple AZs