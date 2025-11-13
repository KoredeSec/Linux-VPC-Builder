# Linux VPC Builder

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://img.shields.io/badge/OS-Linux-blue.svg)](https://www.linux.org/)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://www.python.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

> Build AWS-like Virtual Private Clouds (VPCs) on Linux using network namespaces, bridges, and iptables.

A production-ready CLI tool that recreates cloud VPC functionality entirely on Linux, demonstrating how container networking and cloud infrastructure work under the hood.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## 🎯 Overview

**Linux VPC Builder** is a command-line tool that implements Virtual Private Cloud (VPC) functionality using native Linux networking primitives. It demonstrates the underlying technology that powers:

- 🐳 **Docker networking**
- ☸️ **Kubernetes cluster networking**
- ☁️ **AWS VPC, Azure VNet, GCP VPC**
- 📦 **Container orchestration platforms**

This project is ideal for:
- DevOps engineers learning network fundamentals
- System administrators understanding container networking
- Students studying cloud infrastructure
- Anyone curious about how VPCs work under the hood

---

## ✨ Features

### Core Functionality

- ✅ **VPC Management**
  - Create isolated virtual networks with custom CIDR blocks
  - Multiple VPCs with complete isolation
  - Automatic bridge and gateway configuration
  
- ✅ **Subnet Support**
  - Public subnets with internet access (NAT)
  - Private subnets (internal-only)
  - Automatic IP assignment and routing
  
- ✅ **Network Isolation**
  - Complete VPC-to-VPC isolation by default
  - Namespace-based isolation (like containers)
  - iptables-based access control

- ✅ **VPC Peering**
  - Connect VPCs for controlled cross-network traffic
  - Automatic route propagation
  - Remove isolation rules between peered VPCs

- ✅ **NAT Gateway**
  - Outbound internet access for public subnets
  - iptables MASQUERADE implementation
  - Configurable internet interface

- ✅ **Security Groups**
  - JSON-based firewall rule definitions
  - Port-level access control
  - Protocol-specific rules (TCP/UDP)

- ✅ **Automation & Management**
  - Comprehensive CLI tool (`vpcctl`)
  - Idempotent operations
  - Detailed logging
  - Clean resource teardown

---

## 🏗️ Architecture

### High-Level Design

```
Host System (Ubuntu 24.04)
│
│
├─ VPC 1 (10.0.0.0/16)
│  ├─ Bridge (br-vpc1) ─────────┐ VPC Router
│  ├─ Public Subnet             │
│  │  └─ Namespace (ns-vpc1-web)│ Isolated Environment
│  │     └─ veth pair ──────────┘ Virtual Cable
│  └─ Private Subnet
│     └─ Namespace (ns-vpc1-db)
│
├─ VPC 2 (10.1.0.0/16)
│  └─ Bridge (br-vpc2)
│     └─ Namespace (ns-vpc2-app)
│
└─ Internet (NAT via iptables)
```

### Component Mapping

| Cloud Concept | Linux Implementation |
|---------------|---------------------|
| VPC | Linux Bridge |
| Subnet | Network Namespace |
| Network Interface | veth pair |
| Internet Gateway | iptables NAT (MASQUERADE) |
| Route Table | ip route |
| Security Group | iptables rules |
| VPC Peering | veth pair + routes |

---

## 🚀 Quick Start

### Prerequisites

**Recommended: Use a Virtual Machine (VM)**

This project modifies system networking. Using a VM is **strongly recommended** for:
- ✅ **Safety** - Won't affect your host system
- ✅ **Easy recovery** - VM snapshots let you rollback
- ✅ **Clean testing** - Isolated environment

**Requirements:**
- Ubuntu 22.04 Server (in VirtualBox/VMware)
- 4GB RAM, 2 CPU cores, 20GB disk
- SSH enabled for remote access
- Root/sudo access

### VM Setup (Recommended)

```bash
# On your host machine:
# 1. Install VirtualBox
sudo apt install virtualbox

# 2. Create VM:
#    - Name: vpc-lab
#    - Type: Linux - Ubuntu (64-bit)
#    - RAM: 4096 MB
#    - Disk: 20 GB VDI
#    - Network: NAT

# 3. Install Ubuntu 22.04 Server
#    - Enable OpenSSH during installation
#    - Username: tory-devops (or your choice)

# 4. Setup port forwarding for SSH
VBoxManage modifyvm "vpc-lab" --natpf1 "ssh,tcp,,2222,,22"

# 5. SSH into VM from host
ssh -p 2222 tory-devops@localhost
```

### Transfer Project Files to VM

```bash
# On your host machine, copy files to VM:
scp -P 2222 -r ./linux-vpc-builder/* tory-devops@localhost:~/vpc-project/

# SSH into VM
ssh -p 2222 tory-devops@localhost

# Navigate to project
cd ~/vpc-project
```

### 30-Second Demo (Inside VM)

```bash
# Setup dependencies
sudo ./setup.sh

# Create a VPC
sudo ./vpcctl create-vpc myvpc 10.0.0.0/16

# Add subnets
sudo ./vpcctl add-subnet myvpc web 10.0.1.0/24 public
sudo ./vpcctl add-subnet myvpc db 10.0.2.0/24 private

# View configuration
sudo ./vpcctl list

# Test with comprehensive suite
sudo ./test-vpc.sh

# Cleanup
sudo ./vpcctl delete-vpc myvpc
```

---

## 📦 Installation

### Method 1: Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/linux-vpc-builder.git
cd linux-vpc-builder

# Run setup script (installs dependencies and configures system)
sudo ./setup.sh

# Make vpcctl available system-wide (optional)
sudo make install
```

### Method 2: Manual Installation

```bash
# Install required packages
sudo apt update
sudo apt install -y iproute2 iptables bridge-utils python3 \
    net-tools iputils-ping curl git

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Make vpcctl executable
chmod +x vpcctl

# Verify installation
./vpcctl
```

### Method 3: Using Makefile

```bash
# Install dependencies and configure system
make setup

# Install vpcctl to /usr/local/bin
make install

# Run tests
make test

# Quick demo
make demo

# Cleanup all VPCs
make clean
```

---

## 📖 Usage

### Command Reference

```bash
# VPC Management
sudo ./vpcctl create-vpc <name> <cidr> [interface]    # Create VPC
sudo ./vpcctl delete-vpc <name>                        # Delete VPC
sudo ./vpcctl list                                     # List all VPCs
sudo ./vpcctl logs                                     # View operation logs

# Subnet Management
sudo ./vpcctl add-subnet <vpc> <subnet> <cidr> <type>  # Add subnet
# type: public (has NAT) or private (internal only)

# VPC Peering
sudo ./vpcctl peer-vpcs <vpc1> <vpc2>                  # Create peering

# Security Groups
sudo ./vpcctl apply-rules <vpc> <subnet> <rules.json>  # Apply firewall rules
```

### Command Examples

```bash
# Create production VPC
sudo ./vpcctl create-vpc production 10.0.0.0/16 enp0s3

# Add three-tier architecture
sudo ./vpcctl add-subnet production web-tier 10.0.1.0/24 public
sudo ./vpcctl add-subnet production app-tier 10.0.2.0/24 private
sudo ./vpcctl add-subnet production db-tier 10.0.3.0/24 private

# Create staging VPC
sudo ./vpcctl create-vpc staging 10.1.0.0/16 enp0s3
sudo ./vpcctl add-subnet staging web-tier 10.1.1.0/24 public

# Enable communication between environments
sudo ./vpcctl peer-vpcs production staging

# Apply firewall rules
sudo ./vpcctl apply-rules production web-tier examples/web-firewall.json

# View all VPCs
sudo ./vpcctl list

# Cleanup
sudo ./vpcctl delete-vpc production
sudo ./vpcctl delete-vpc staging
```

---

## 💡 Examples

### Example 1: Simple Web Application

```bash
# Create VPC
sudo ./vpcctl create-vpc webapp 10.0.0.0/16

# Add public subnet for web server
sudo ./vpcctl add-subnet webapp frontend 10.0.1.0/24 public

# Deploy web server in namespace
sudo ip netns exec ns-webapp-fronte python3 -m http.server 80 &

# Test access
curl http://10.0.1.1:80
```

### Example 2: Multi-Tier Architecture

```bash
# Create VPC
sudo ./vpcctl create-vpc enterprise 172.16.0.0/16

# Create tiers
sudo ./vpcctl add-subnet enterprise web-dmz 172.16.1.0/24 public
sudo ./vpcctl add-subnet enterprise app-tier 172.16.2.0/24 private
sudo ./vpcctl add-subnet enterprise data-tier 172.16.3.0/24 private

# Apply security rules
cat > web-dmz-rules.json <<EOF
{
  "subnet": "172.16.1.0/24",
  "ingress": [
    {"port": 80, "protocol": "tcp", "action": "allow"},
    {"port": 443, "protocol": "tcp", "action": "allow"}
  ]
}
EOF

sudo ./vpcctl apply-rules enterprise web-dmz web-dmz-rules.json
```

### Example 3: Development Environment Isolation

```bash
# Create isolated environments
sudo ./vpcctl create-vpc dev 10.10.0.0/16
sudo ./vpcctl create-vpc test 10.20.0.0/16
sudo ./vpcctl create-vpc prod 10.30.0.0/16

# Add subnets to each
for env in dev test prod; do
    sudo ./vpcctl add-subnet $env app 10.${env:0:1}0.1.0/24 public
done

# Verify isolation
sudo ip netns exec ns-dev-app ping -c 2 10.20.1.1  # Should fail

# Enable dev-test communication only
sudo ./vpcctl peer-vpcs dev test
```

---

## 🧪 Testing

### Run Complete Test Suite

```bash
# Comprehensive automated tests
sudo ./test-vpc.sh
```

The test suite validates:
- ✅ VPC creation and configuration
- ✅ Subnet creation (public and private)
- ✅ Web server deployment in namespaces
- ✅ Inter-subnet communication
- ✅ NAT gateway functionality
- ✅ VPC isolation
- ✅ VPC peering
- ✅ Firewall rule enforcement
- ✅ Clean resource teardown

### Manual Testing

```bash
# Test 1: Enter a namespace
sudo ip netns exec ns-production-web bash
# Now you're inside the namespace
ip addr show
ping 8.8.8.8
exit

# Test 2: Check routing
sudo ip netns exec ns-production-web ip route

# Test 3: View iptables rules
sudo ip netns exec ns-production-web iptables -L -n -v

# Test 4: Verify isolation
sudo ./vpcctl list
```

### Demo Script

Run a narrated demonstration:

```bash
# 5-minute comprehensive demo
sudo ./demo-script.sh
```

---

## 📁 Project Structure

```
linux-vpc-builder/
├── vpcctl                    # Main CLI tool (Python)
├── test-vpc.sh               # Comprehensive test suite
├── setup.sh                  # Dependency installation & system setup
├── cleanup.sh                # Emergency cleanup script
├── demo-script.sh            # Automated demo for presentations
├── Makefile                  # Build automation
├── README.md                 # This file
├── LICENSE                   # MIT License
└── examples/                 # Example configurations
    ├── web-firewall.json     # Web server security rules
    └── db-firewall.json      # Database security rules
```

### Key Files Explained

| File | Purpose |
|------|---------|
| `vpcctl` | Main CLI tool - handles all VPC operations |
| `test-vpc.sh` | Automated test suite - validates all functionality |
| `setup.sh` | Installs dependencies and configures system |
| `cleanup.sh` | Emergency cleanup - removes orphaned resources |
| `demo-script.sh` | Narrated demo for video recordings |
| `Makefile` | Build automation - setup, test, install, clean |
| `examples/*.json` | Firewall rule templates |

---

## 🔧 How It Works

### 1. VPC Creation Process

When you create a VPC:

```bash
sudo ./vpcctl create-vpc myvpc 10.0.0.0/16
```

**What happens:**

1. **Creates Linux Bridge** (acts as VPC router)
   ```bash
   ip link add br-myvpc type bridge
   ip link set br-myvpc up
   ```

2. **Assigns Gateway IP** (first usable IP in CIDR)
   ```bash
   ip addr add 10.0.0.1/16 dev br-myvpc
   ```

3. **Configures NAT** (for internet access)
   ```bash
   iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o enp0s3 -j MASQUERADE
   iptables -A FORWARD -i br-myvpc -j ACCEPT
   ```

4. **Adds Isolation Rules** (blocks other VPCs)
   ```bash
   iptables -I FORWARD -s 10.0.0.0/16 -d <other_vpc_cidr> -j DROP
   ```

### 2. Subnet Creation Process

When you add a subnet:

```bash
sudo ./vpcctl add-subnet myvpc web 10.0.1.0/24 public
```

**What happens:**

1. **Creates Network Namespace** (isolated environment)
   ```bash
   ip netns add ns-myvpc-web
   ```

2. **Creates veth Pair** (virtual cable)
   ```bash
   ip link add veth-web type veth peer name veth-ns-web
   ```

3. **Connects to Bridge**
   ```bash
   ip link set veth-web master br-myvpc
   ip link set veth-web up
   ```

4. **Configures Namespace**
   ```bash
   # Move veth end into namespace
   ip link set veth-ns-web netns ns-myvpc-web
   
   # Assign IP and routing
   ip netns exec ns-myvpc-web ip addr add 10.0.1.1/24 dev veth-ns-web
   ip netns exec ns-myvpc-web ip route add 10.0.0.0/16 dev veth-ns-web
   ip netns exec ns-myvpc-web ip route add default via 10.0.0.1
   ```

### 3. Packet Flow Example

**Scenario:** Web server in namespace accesses internet

```
1. Process in ns-myvpc-web sends packet to 8.8.8.8
   └─ Source IP: 10.0.1.1

2. Namespace routing → send to gateway 10.0.0.1
   └─ Packet goes through veth-ns-web

3. Arrives at veth-web (connected to bridge)
   └─ Bridge forwards to host network

4. iptables NAT (MASQUERADE) rule activates
   └─ Source IP changed: 10.0.1.1 → 192.168.1.100 (host IP)

5. Packet exits via enp0s3 to internet

6. Response returns
   └─ NAT translates back: 192.168.1.100 → 10.0.1.1
   └─ Routes back through bridge → veth → namespace

7. Process receives response
```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue 1: "Nexthop has invalid gateway"

**Error:**
```
Error: Nexthop has invalid gateway
```

**Solution:**
This is fixed in the latest version. The gateway IP is now reachable via explicit route:
```bash
ip netns exec ns ip route add <vpc_cidr> dev veth-ns
ip netns exec ns ip route add default via <gateway_ip> dev veth-ns
```

#### Issue 2: No Internet Access from Namespace

**Debug:**
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should output: 1

# Check NAT rules
sudo iptables -t nat -L -n -v | grep MASQUERADE

# Test gateway connectivity
sudo ip netns exec ns-myvpc-web ping 10.0.0.1
```

**Fix:**
```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/16 -o enp0s3 -j MASQUERADE
```

#### Issue 3: VPCs Not Isolated

**Check isolation rules:**
```bash
sudo iptables -L FORWARD -n -v | grep DROP
```

**Fix:**
```bash
sudo iptables -I FORWARD -s 10.0.0.0/16 -d 10.1.0.0/16 -j DROP
```

#### Issue 4: Orphaned Resources After Deletion

**Symptoms:** Namespaces or bridges remain after `delete-vpc`

**Fix:**
```bash
# Use cleanup script
sudo ./cleanup.sh

# Or manual cleanup
sudo ip netns delete <namespace>
sudo ip link delete <bridge>
```

### Getting Help

1. **Check logs:**
   ```bash
   sudo ./vpcctl logs
   cat ~/.vpcctl/vpcctl.log
   ```

2. **Verify system state:**
   ```bash
   ip netns list
   ip link show | grep br-
   sudo iptables -t nat -L -n
   ```

3. **Run diagnostics:**
   ```bash
   # Inside namespace
   sudo ip netns exec <namespace> ip addr
   sudo ip netns exec <namespace> ip route
   sudo ip netns exec <namespace> ping 8.8.8.8
   ```

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest new features
- 📝 Improve documentation
- 🧪 Add more tests
- 🎨 Create better examples

### Development Setup

```bash
# Fork and clone
git clone https://github.com/yourusername/linux-vpc-builder.git
cd linux-vpc-builder

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
sudo ./test-vpc.sh

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Open Pull Request
```

### Coding Standards

- Python code follows PEP 8
- Bash scripts use `set -e` for error handling
- All functions must have docstrings
- Add tests for new features

---

## 📄 License

```
MIT License

Copyright (c) 2025 Ibrahim Yusuf (Tory)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- **HNG Internship** - For the project opportunity and learning experience
  - Website: [https://hng.tech/internship](https://hng.tech/internship)
  - Premium: [https://hng.tech/premium](https://hng.tech/premium)

- **Linux Networking Community** - For excellent documentation
  - Network Namespaces: [man7.org](https://man7.org/linux/man-pages/man7/network_namespaces.7.html)
  - iptables: [netfilter.org](https://www.netfilter.org/)

- **Inspiration**
  - Docker networking architecture
  - AWS VPC design principles
  - Kubernetes networking model

---

## 📚 Additional Resources

### Related Projects

- [Docker libnetwork](https://github.com/moby/libnetwork)
- [CNI - Container Network Interface](https://github.com/containernetworking/cni)
- [Calico networking](https://github.com/projectcalico/calico)

### Further Reading

- [Linux Network Namespaces](https://blog.scottlowe.org/2013/09/04/introducing-linux-network-namespaces/)
- [Understanding Docker Networking](https://docs.docker.com/network/)
- [iptables Tutorial](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)

---

## 👨‍💻 Author

**Ibrahim Yusuf (Tory)**

🎓 **President** – NACSS_UNIOSUN (Nigeria Association Of CyberSecurity Students, Osun State University)  
🔐 **Certifications:** Certified in Cybersecurity (ISC² CC) | Microsoft SC-200  
💼 **Focus:** Cloud Architecture, DevSecOps, Automation, Threat Intel, Cybersecurity  

### Connect & Follow

- 🐙 **GitHub:** [@KoredeSec](https://github.com/KoredeSec)
- ✍️ **Medium:** [Ibrahim Yusuf](https://medium.com/@KoredeSec)
- 🐦 **X (Twitter):** [@KoredeSec](https://x.com/KoredeSec)
- 💼 **LinkedIn:** Restricted currently

### Other Projects

-  **AdwareDetector** [AdwareDetector](https://github.com/KoredeSec/AdwareDetector) 
-  **threat-intel-aggregator**[threat-intel-aggregator](https://github.com/KoredeSec/threat-intel-aggregator)
-  **azure-sentinel-home-soc** [azure-sentinel-home-soc](https://github.com/KoredeSec/azure-sentinel-home-soc)


### Support This Project

If you find this project helpful:
- ⭐ Star this repository
- 🐛 Report issues
- 📢 Share with others
- 💬 Leave feedback

---

## 🎓 About This Project

This project was completed as part of the **HNG DevOps Internship Stage 4** challenge. The goal was to recreate AWS VPC functionality using only Linux networking primitives, demonstrating deep understanding of:

- Network virtualization
- Container networking fundamentals
- Cloud infrastructure concepts
- DevOps automation practices


---

<div align="center">

**⭐ If this project helped you understand VPCs and Linux networking, please star it! ⭐**

Made with ❤️ for the DevOps community

</div>