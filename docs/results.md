# Experimental Results Documentation

> This document records the results of the simulation-based experiments conducted for the research paper:  
> *"A Comparative Study of Infrastructure Automation Tools in Cloud Environments"*

---

## Environment

| Parameter | Value |
|-----------|-------|
| Cloud Platform | AWS (ap-south-1, Mumbai) |
| Managed Node Type | EC2 t3.medium (2 vCPU, 4 GB RAM, Ubuntu 22.04) |
| Control Node Type | EC2 t3.large (2 vCPU, 8 GB RAM, Ubuntu 22.04) |
| Repetitions per test | 5 (outliers >2σ excluded) |
| Monitoring | AWS CloudWatch + htop |

---

## Deployment Time Results (minutes)

| Node Count | Ansible | Terraform | Puppet |
|------------|---------|-----------|--------|
| 5 nodes    | 2.1     | 3.4       | 5.2    |
| 10 nodes   | 4.2     | 6.8       | 9.1    |
| 25 nodes   | 9.8     | 14.3      | 21.6   |
| 50 nodes   | 18.5    | 27.1      | 43.2   |

**Scale factor (5 → 50 nodes):** Ansible 8.8x | Terraform 7.9x | Puppet 8.3x

---

## Resource Utilization (10-node deployment)

| Metric | Ansible | Terraform | Puppet |
|--------|---------|-----------|--------|
| Avg. CPU Usage | 18% | 29% | 41% |
| Avg. RAM Usage | 312 MB | 487 MB | 623 MB |

---

## Setup Time (one-time, first run)

| Tool | Setup Time | Steps Required |
|------|-----------|----------------|
| Ansible | ~12 min | pip install + ansible.cfg + inventory |
| Terraform | ~20 min | binary install + terraform init + S3 backend |
| Puppet | ~55 min | Puppet master + CA init + agent on each node + cert signing |

---

## Qualitative Scoring (1–5 per criterion)

| Criterion | Ansible | Terraform | Puppet |
|-----------|---------|-----------|--------|
| Deployment Speed | 5 | 3 | 2 |
| Scalability | 4 | 5 | 4 |
| Ease of Use | 5 | 3 | 2 |
| Resource Efficiency | 5 | 3 | 2 |
| AWS Cloud Integration | 5 | 5 | 3 |
| Multi-Cloud Support | 2 | 5 | 3 |
| Config Compliance | 4 | 3 | 5 |
| Community & Ecosystem | 5 | 5 | 3 |
| Setup Simplicity | 5 | 3 | 1 |
| Learning Curve | 5 | 3 | 2 |
| **TOTAL** | **45/50** | **38/50** | **26/50** |

---

## Key Findings

1. **Ansible** is 38% faster than Terraform and 54% faster than Puppet at 10 nodes
2. **Ansible** consumes 56% less CPU than Puppet on the control node
3. **Puppet** setup requires ~4.6x more time than Ansible
4. **Terraform** leads in multi-cloud support and stateful provisioning safety
5. All three tools scale approximately linearly from 5 to 50 nodes

---

## Benchmark Output Format

The `benchmark/benchmark.sh` script generates a CSV file with the following columns:

```
Tool, Nodes, Run, Duration_seconds, CPU_percent, RAM_mb, Status
ansible, 10, 1, 252, 17.8, 308, SUCCESS
ansible, 10, 2, 254, 18.1, 315, SUCCESS
...
```
