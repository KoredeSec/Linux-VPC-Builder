# vpcctl - Virtual Private Cloud on Linux

Build and manage VPCs using Linux networking primitives.

## Quick Start
```bash
# Setup
sudo ./setup.sh

# Create VPC
sudo ./vpcctl create-vpc prod 10.0.0.0/16

# Add subnets
sudo ./vpcctl add-subnet prod web 10.0.1.0/24 public
sudo ./vpcctl add-subnet prod db 10.0.2.0/24 private

# List VPCs
sudo ./vpcctl list

# Test
sudo ./test-vpc.sh

# Cleanup
sudo ./cleanup.sh
```

## Architecture
VPC (10.0.0.0/16)
├─ Bridge (br-vpc) - VPC Router
├─ Public Subnet (10.0.1.0/24)
│  └─ Namespace with NAT access
└─ Private Subnet (10.0.2.0/24)
└─ Namespace (internal only)

## Requirements

- Ubuntu 22.04+ (VM recommended)
- Root access
- 4GB RAM, 2 CPU cores

## Commands

See `./vpcctl` for full command list.

## Testing

Run `sudo ./test-vpc.sh` for comprehensive tests.

## Author

DevOps Intern - HNG Stage 4 Task

