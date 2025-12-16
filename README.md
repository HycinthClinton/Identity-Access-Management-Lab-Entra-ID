# Azure Administration Labs (Manual & Automated)

This repository contains a collection of **hands-on Azure administration labs**, built first using the Azure Portal and then recreated using **PowerShell automation**.

Each lab is intentionally done in two phases:
1. Manual implementation to understand the platform  
2. Automated implementation to make it repeatable and scalable  

This mirrors how real Azure admins learn and work.

---

## Purpose of This Repository

- Build strong Azure fundamentals through hands-on labs  
- Understand what the Azure Portal does behind the scenes  
- Translate manual steps into PowerShell automation  
- Practice identity, RBAC, compute, and networking  
- Prepare for AZ-104 using practical scenarios  

---

## Labs Included

### 1. Entra ID Identity & RBAC Lab

**Manual Lab (Azure Portal)**  
**Path:** `/entra-id-identity-manual/`

Covers the full setup using the Azure Portal:
- Entra ID users and security groups
- Group membership management
- Role assignment at resource group scope
- Windows Server VM deployment
- Availability zone selection

This version focuses on understanding each Azure component and decision.

---

**Automated Lab (PowerShell)**  

Recreates the same environment using PowerShell:
- User and group creation
- Group-based RBAC
- VM and networking deployment
- Spot VM configuration
- One-command, repeatable setup

This version focuses on automation and operational consistency.

---

## Technologies Used

- Azure Portal
- Azure PowerShell (Az module)
- AzureAD module
- Microsoft Entra ID
- Azure Virtual Machines
- Azure RBAC
- Azure Networking

---

## How to Use This Repository

Each lab folder contains:
- A dedicated `README.md`
- Step-by-step instructions or scripts
- Clear learning objectives

You can follow the manual lab first, then run the automated version to reinforce understanding.

---

## Disclaimer

These labs are built for **learning and demonstration purposes only**.  
They may include simplified configurations that are not intended for production use.

---

## Roadmap

Planned additions:
- Microsoft Graph-based identity automation
- Network Security Group labs
- Storage and access control labs
- Monitoring and alerting labs
- Cleanup and teardown scripts

---

## Author

Built as part of hands-on Azure administration practice and continuous learning.
