# Terraform Project with Nginx and Flask

## Project Overview

This project sets up a VPC in AWS with both public and private subnets, deploying EC2 instances as Nginx reverse proxies and Flask web application backends. It also configures NAT Gateway, Internet Gateway, and two load balancers (public and internal).

## Architecture

* **VPC**: Custom CIDR blocks for public and private subnets.
* **Public Subnets**: 10.0.0.0/24 and 10.0.2.0/24 containing Nginx reverse proxy EC2 instances.
* **Private Subnets**: 10.0.1.0/24 and 10.0.3.0/24 containing Flask application backends.
* **NAT Gateway**: For private subnets to access the internet.
* **Internet Gateway**: For public subnet internet access.
* **Load Balancers**:

  * Public ALB: Routes traffic to Nginx proxies.
  * Internal ALB: Routes traffic from proxies to private backend servers.

## Terraform Setup

### Workspace

* Create a new workspace `dev`.

  ```bash
  terraform workspace new dev
  ```

### Backend

* Configure remote backend for state file storage.

### Modules

* Each module is implemented with:

  * `main.tf`
  * `variables.tf`
  * `outputs.tf`
* Custom modules are used for VPC, EC2 instances, and load balancers.

### Provisioners

* **Remote-exec**: Installs Nginx or Apache on EC2 instances.
* **Local-exec**: Prints all IPs to `all-ips.txt` in the format:

  ```
    public-ip1 1.1.1.1
    public-ip2 2.2.2.2
  ```

- **File**: Copies Flask application files from local machine to private EC2 instances.

### Data Sources
- AWS AMI IDs are dynamically retrieved using Terraform data sources.

## Flask Application
- Minimal Flask app deployed to private EC2 instances.
- Serves a styled static page.
- Directory structure:

```
app/
├── app.py
├── static/
│   └── style.css
└── templates/
    └── index.html
```

### Accessing the App

* Access public ALB -> Nginx proxies -> Internal ALB -> Flask backends.

## Trying It Yourself

1. Clone the repository:

```bash
git clone <repository-url>
cd <project-folder>
```

2. Create your ssh key:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform_key -C "terraform@project"
```

3. Create your S3 bucket for the terraform state file, then update `backend.tf` to use it.

4. Configure Terraform variables in `terraform.tfvars` or via environment variables.

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars # configure the ssh key you generated.
```

5. Initialize Terraform and select workspace:

```bash
terraform init
terraform workspace new dev
terraform workspace select dev
```

6. Apply Terraform to create resources:

```bash
terraform apply
```

7. Confirm all EC2 instances are running and check `all-ips.txt` for public IPs.

8. Verify the Flask application through the public ALB DNS.

9. When done, destroy resources to avoid charges:

```bash
terraform destroy
```

## Notes

* Terraform variables should be configured before `terraform apply`.
* IP addresses and DNS names of EC2 instances and ALBs are saved in `all-ips.txt`.

## Author

* Omar Abdelgawad
