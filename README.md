# OCI Stable Diffusion XL - fine tuning

This repo enables you to create a data science project in OCI that will allows you fine tune stable diffusion XL with your own images.

First execute this the terraform, and after that go to the created notebook and execute the cells.

*You'll need access to GPUs to execute eveything.*

See the next video with all the steps.

## Requirements
- Terraform
- ssh-keygen

## Configuration

1. Follow the instructions to add the authentication to your tenant https://medium.com/@carlgira/install-oci-cli-and-configure-a-default-profile-802cc61abd4f.
2. Clone this repository:
    ```bash
    git clone https://github.com/carlgira/oci-tf-odsc-sdxl
    ```

3. Set three variables in your path. 
- The tenancy OCID, 
- The comparment OCID where the instance will be created.
- The number of instances to create
- The "Region Identifier" of region of your tenancy.
> **Note**: [More info on the list of available regions here.](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm)

```bash
    export TF_VAR_tenancy_ocid='<tenancy-ocid>'
    export TF_VAR_compartment_ocid='<comparment-ocid>'
    export TF_VAR_region='<oci-region>'
```

## Build

To build the terraform solution, simply execute: 

```bash
    terraform init
    terraform plan
    terraform apply
```

## Notebook
Go to the data science project and open the notebook session that was created. You'll need to follow the all the instructions.

## Acknowledgements

* **Authors** - [Carlos Giraldo](https://www.linkedin.com/in/carlos-giraldo-a79b073b/), Oracle
              - [Bob Peulen](https://www.linkedin.com/in/bobpeulen/), Oracle
* **Last Updated Date** - August 15th, 2023
