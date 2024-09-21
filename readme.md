# DevOps Exercise

## Introduction 
This repository includes Terraform code to provision secure AWS cloud infrastructure using Amazon Network Firewall (ANF).

### Notes on the Project

1. This Terraform project is not intended for production or actual use in real-life scenarios. The project is not modularized or reusable.
  
2. The project does not take into consideration multiple availability zones (AZs). Ideally, for production workloads, we would provision our infrastructure across multiple AZs.

---

## Running the Project
The project runs on an AWS burner account created for this exercise.

To execute the Terraform code, you need to create an `init.sh` file and populate it with the necessary configuration:

```bash
cp init.sh.example init.sh
```

After creating the file, fill in the required variables. This Terraform project will also provision FluxCD to enable GitOps. An SSH key is needed to be linked with a GitHub repository as a deploy key. Set the following environment variables to connect to the repository:

- `TF_VAR_github_token`
- `TF_VAR_private_key_pem`

After populating the `init.sh` file, export the variables as environment variables:

```bash
source init.sh
```

To confirm if the account is connected successfully, run:

```bash
aws sts get-caller-identity
```

Next, initialize Terraform:

```bash
terraform init
```

Then, run the plan:

```bash
terraform plan
```

Finally, apply the changes:

```bash
terraform apply
```

## Architecture 

The provisioned cloud infrastructure includes four subnet types:

1. **DMZ** (Firewall dedicated subnet)
2. **Public** (Subnet for internet-reachable hosts)
3. **Private** (Subnet for outbound-only internet connections)
4. **Isolated** (Subnet for hosts that do not require internet access)

All outbound and inbound traffic flows through ANF. Since we are using a network firewall, achieving network symmetry is mandatory for proper traffic flow in the system.

The figure below illustrates a high-level design of the cloud infrastructure that this Terraform project provisions:

![Alt text](./docs/Infra.png?raw=true "Infra Diagram")

