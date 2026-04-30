# cloud-automation-tools-study

> **Companion code repository** for the research paper:  
> *"A Comparative Study of Infrastructure Automation Tools in Cloud Environments"*  
> Risham Goyal, Vaibhav Khanna, Sujal Jain — Chitkara University, 2024

---

## 📌 Overview

This repository contains the automation scripts used in the experimental evaluation of three major Infrastructure as Code (IaC) and configuration management tools:

| Tool | Version | Purpose in Study |
|------|---------|-----------------|
| **Ansible** | 2.17.x | Configuration management & app deployment |
| **Terraform** | 1.9.x | Infrastructure provisioning on AWS |
| **Puppet** | 8.x | Agent-based configuration management |

All three tools perform the **same standard task**:
1. Provision an EC2 instance (Ubuntu 22.04 LTS, t3.medium) on AWS
2. Install and configure Nginx web server (v1.24.x)
3. Deploy a custom application configuration
4. Verify service health on port 80

---

## 📁 Repository Structure

```
cloud-automation-tools-study/
│
├── ansible/                    # Ansible implementation
│   ├── playbook.yml            # Main playbook (47 lines)
│   ├── inventory/
│   │   └── aws_ec2.yml         # Dynamic AWS EC2 inventory
│   ├── ansible.cfg             # Ansible configuration
│   └── roles/
│       └── webserver/
│           ├── tasks/
│           │   └── main.yml    # Task definitions
│           ├── handlers/
│           │   └── main.yml    # Service handlers
│           └── templates/
│               └── nginx.conf.j2  # Nginx config template
│
├── terraform/                  # Terraform implementation
│   ├── main.tf                 # Main configuration (EC2, SG, provisioner)
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output definitions
│   └── terraform.tfvars.example  # Example variable values
│
├── puppet/                     # Puppet implementation
│   ├── manifests/
│   │   └── site.pp             # Main manifest entry point
│   └── modules/
│       └── webserver/
│           ├── manifests/
│           │   └── init.pp     # Webserver class definition
│           └── templates/
│               └── nginx.conf.epp  # Nginx config template
│
├── benchmark/
│   └── benchmark.sh            # Timing script for all three tools
│
├── docs/
│   └── results.md              # Experimental results documentation
│
└── README.md
```

---

## ⚙️ Prerequisites

### Common
- AWS Account with IAM user/role having `EC2FullAccess` and `SSM` permissions
- AWS CLI configured (`aws configure`)
- An existing EC2 Key Pair

### Ansible
```bash
pip install ansible boto3 botocore
ansible-galaxy collection install amazon.aws community.aws
```

### Terraform
```bash
# Download from https://developer.hashicorp.com/terraform/install
terraform -version  # should be >= 1.9.0
```

### Puppet
```bash
# On Puppet Master (separate EC2)
wget https://apt.puppet.com/puppet8-release-jammy.deb
sudo dpkg -i puppet8-release-jammy.deb
sudo apt-get update && sudo apt-get install -y puppetserver
```

---

## 🚀 Usage

### Ansible
```bash
cd ansible/
# Edit inventory/aws_ec2.yml with your region and filters
ansible-playbook playbook.yml -i inventory/aws_ec2.yml
```

### Terraform
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### Puppet
```bash
# On Puppet Master
cd puppet/
sudo cp -r modules/webserver /etc/puppetlabs/code/environments/production/modules/
sudo cp manifests/site.pp /etc/puppetlabs/code/environments/production/manifests/
# On each agent node:
sudo puppet agent --test
```

### Benchmark (all tools)
```bash
cd benchmark/
chmod +x benchmark.sh
./benchmark.sh
```

---

## 📊 Experimental Results Summary

| Metric | Ansible | Terraform | Puppet |
|--------|---------|-----------|--------|
| Deployment (10 nodes) | 4.2 min | 6.8 min | 9.1 min |
| Deployment (50 nodes) | 18.5 min | 27.1 min | 43.2 min |
| Avg. CPU Usage | 18% | 29% | 41% |
| Avg. RAM Usage | 312 MB | 487 MB | 623 MB |
| Setup Time | ~12 min | ~20 min | ~55 min |
| Qualitative Score | **45/50** | 38/50 | 26/50 |

Full results and analysis are documented in [`docs/results.md`](docs/results.md).

---

## 🔬 Research Context

This code supports a comparative study evaluating the tools across six dimensions:
- Deployment Speed & Scalability
- Resource Utilization (CPU & RAM)
- Ease of Use & Learning Curve
- Cloud Integration (AWS)
- Configuration Consistency
- Setup Complexity

**Conclusion:** Ansible demonstrated superior overall performance for general-purpose AWS cloud automation, achieving the fastest deployment times and lowest resource overhead due to its agentless, push-based architecture.

---

## 👥 Authors

| Name | Roll No. | Email |
|------|----------|-------|
| Risham Goyal | 2210992157 | risham2157.be22@chitkara.edu.in |
| Vaibhav Khanna | 2210992486 | vaibhav2486.be22@chitkara.edu.in |
| Sujal Jain | 2210994845 | sujal4845.be22@chitkara.edu.in |

**Department of Computer Science and Engineering**  
Chitkara University, Punjab, India

---

## 📄 License

This project is licensed under the MIT License.
